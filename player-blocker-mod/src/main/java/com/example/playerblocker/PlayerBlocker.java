package com.example.playerblocker;

import com.mojang.brigadier.Command;
import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.StringArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.suggestion.SuggestionProvider;
import com.mojang.brigadier.suggestion.Suggestions;
import com.mojang.brigadier.suggestion.SuggestionsBuilder;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.SharedSuggestionProvider;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.neoforged.bus.api.EventPriority;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.CommandEvent;
import net.neoforged.neoforge.event.RegisterCommandsEvent;
import net.neoforged.neoforge.event.server.ServerStartingEvent;
import net.neoforged.fml.common.Mod;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Mod("playerblocker")
public class PlayerBlocker {
    private static final Set<String> PROTECTED = new HashSet<>();
    private static final Set<String> ADMINS = new HashSet<>();
    private static Path configFile;
    private static Path adminsFile;
    private static MinecraftServer serverInstance;

    public PlayerBlocker() {
        NeoForge.EVENT_BUS.addListener(EventPriority.HIGHEST, (ServerStartingEvent event) -> onServerStarting(event));
        NeoForge.EVENT_BUS.addListener((CommandEvent event) -> onCommand(event));
        NeoForge.EVENT_BUS.addListener((RegisterCommandsEvent event) -> onRegisterCommands(event));
        System.out.println("[PlayerBlocker] Loaded");
    }

    private void onServerStarting(ServerStartingEvent event) {
        serverInstance = event.getServer();
        Path configDir = serverInstance.getServerDirectory().resolve("config");
        configFile = configDir.resolve("playerblocker.json");
        adminsFile = configDir.resolve("playerblocker_admins.json");
        loadConfig();
        loadAdmins();
        System.out.println("[PlayerBlocker] Protected: " + String.join(", ", PROTECTED));
        System.out.println("[PlayerBlocker] Admins: " + String.join(", ", ADMINS));
    }

    private boolean isAdmin(CommandSourceStack source) {
        Entity entity = source.getEntity();
        if (entity instanceof ServerPlayer player) {
            return ADMINS.contains(player.getGameProfile().getName());
        }
        return true; // console is always admin
    }

    private boolean isOp(CommandSourceStack source) {
        return source.hasPermission(2);
    }

    private void onCommand(CommandEvent event) {
        String command = event.getParseResults().getReader().getString();

        // Only intercept /player commands
        if (!command.startsWith("/player") && !command.startsWith("player"))
            return;

        String[] parts = command.split(" ");
        if (parts.length < 2)
            return;

        String targetName = parts[1];

        if (PROTECTED.contains(targetName)) {
            // FIX: Allow the player to use /player on themselves even if protected
            Entity entity = event.getParseResults().getContext().getSource().getEntity();
            if (entity instanceof ServerPlayer player) {
                if (player.getGameProfile().getName().equals(targetName)) {
                    // Player is targeting themselves — allow the command
                    return;
                }
            }

            // Block the command for others
            event.setCanceled(true);

            Entity sourceEntity = event.getParseResults().getContext().getSource().getEntity();
            if (sourceEntity instanceof ServerPlayer sourcePlayer) {
                sourcePlayer.sendSystemMessage(Component.literal("§cPlayer " + targetName + " is protected from /player commands"));
            }
        }
    }

    private void onRegisterCommands(RegisterCommandsEvent event) {
        CommandDispatcher<CommandSourceStack> dispatcher = event.getDispatcher();

        dispatcher.register(
            Commands.literal("playerprotect")
                .then(Commands.literal("list")
                    .executes(this::cmdList)
                )
                .then(Commands.literal("add")
                    .then(Commands.argument("name", StringArgumentType.word())
                        .suggests(this::suggestPlayers)
                        .executes(this::cmdAdd)
                    )
                )
                .then(Commands.literal("remove")
                    .then(Commands.argument("name", StringArgumentType.word())
                        .suggests(this::suggestProtected)
                        .executes(this::cmdRemove)
                    )
                )
                .then(Commands.literal("admins")
                    .requires(this::isOpOrAdmin)
                    .then(Commands.literal("list")
                        .executes(this::cmdAdminsList)
                    )
                    .then(Commands.literal("add")
                        .then(Commands.argument("name", StringArgumentType.word())
                            .suggests(this::suggestPlayers)
                            .executes(this::cmdAdminsAdd)
                        )
                    )
                    .then(Commands.literal("remove")
                        .then(Commands.argument("name", StringArgumentType.word())
                            .suggests(this::suggestAdmins)
                            .executes(this::cmdAdminsRemove)
                        )
                    )
                    .executes(cmdAdminsUsage)
                )
        );
    }

    private final Command<CommandSourceStack> cmdAdminsUsage = context -> {
        context.getSource().sendSuccess(() -> Component.literal("§eUsage: /playerprotect list|add <name>|remove <name>"), false);
        return 1;
    };

    private boolean isOpOrAdmin(CommandSourceStack source) {
        return isOp(source) || isAdmin(source);
    }

    private boolean canAddTarget(CommandSourceStack source, String targetName) {
        // Admins and ops can add anyone
        if (isAdmin(source) || isOp(source))
            return true;
        // Regular players can only add themselves
        Entity entity = source.getEntity();
        if (entity instanceof ServerPlayer player) {
            return player.getGameProfile().getName().equals(targetName);
        }
        return false;
    }

    private boolean canRemoveTarget(CommandSourceStack source) {
        // Only ops and admins can remove protection
        return isAdmin(source) || isOp(source);
    }

    private CompletableFuture<Suggestions> suggestPlayers(CommandContext<CommandSourceStack> context, SuggestionsBuilder builder) {
        List<String> names = new ArrayList<>();

        // Add online players
        if (serverInstance != null) {
            for (ServerPlayer player : serverInstance.getPlayerList().getPlayers()) {
                names.add(player.getGameProfile().getName());
            }
        }

        // Also scan usercache.json for offline players
        Path cacheFile = serverInstance.getServerDirectory().resolve("usercache.json");
        if (Files.exists(cacheFile)) {
            try {
                String content = Files.readString(cacheFile);
                int idx = 0;
                while ((idx = content.indexOf("\"name\":", idx)) >= 0) {
                    int start = content.indexOf('"', idx + 8) + 1;
                    int end = content.indexOf('"', start);
                    if (start > 0 && end > start) {
                        names.add(content.substring(start, end));
                    }
                    idx = end;
                }
            } catch (IOException e) {
                System.err.println("[PlayerBlocker] Failed to read usercache.json: " + e.getMessage());
            }
        }

        return SharedSuggestionProvider.suggest(names.stream().distinct(), builder);
    }

    private CompletableFuture<Suggestions> suggestProtected(CommandContext<CommandSourceStack> context, SuggestionsBuilder builder) {
        return SharedSuggestionProvider.suggest(PROTECTED, builder);
    }

    private CompletableFuture<Suggestions> suggestAdmins(CommandContext<CommandSourceStack> context, SuggestionsBuilder builder) {
        return SharedSuggestionProvider.suggest(ADMINS, builder);
    }

    private int cmdList(CommandContext<CommandSourceStack> context) {
        if (PROTECTED.isEmpty()) {
            context.getSource().sendSuccess(() -> Component.literal("§eNo protected player names"), false);
        } else {
            context.getSource().sendSuccess(() -> Component.literal("§eProtected player names:"), false);
            PROTECTED.stream().sorted().forEach(name ->
                context.getSource().sendSuccess(() -> Component.literal(" §7- §f" + name), false)
            );
        }
        return 1;
    }

    private int cmdAdd(CommandContext<CommandSourceStack> context) {
        String name = StringArgumentType.getString(context, "name");

        if (!canAddTarget(context.getSource(), name)) {
            context.getSource().sendFailure(Component.literal("§cYou can only add yourself to the protection list"));
            return 0;
        }

        if (PROTECTED.add(name)) {
            saveConfig();
            context.getSource().sendSuccess(() -> Component.literal("§aAdded " + name + " to protection list"), true);
        } else {
            context.getSource().sendFailure(Component.literal(name + " is already protected"));
        }
        return 1;
    }

    private int cmdRemove(CommandContext<CommandSourceStack> context) {
        if (!canRemoveTarget(context.getSource())) {
            context.getSource().sendFailure(Component.literal("§cOnly ops and admins can remove protection"));
            return 0;
        }

        String name = StringArgumentType.getString(context, "name");

        if (PROTECTED.remove(name)) {
            saveConfig();
            context.getSource().sendSuccess(() -> Component.literal("§aRemoved " + name + " from protection list"), true);
        } else {
            context.getSource().sendFailure(Component.literal(name + " is not in the protection list"));
        }
        return 1;
    }

    private int cmdAdminsList(CommandContext<CommandSourceStack> context) {
        if (ADMINS.isEmpty()) {
            context.getSource().sendSuccess(() -> Component.literal("§eNo additional admins configured"), false);
        } else {
            context.getSource().sendSuccess(() -> Component.literal("§ePlayerBlocker admins:"), false);
            ADMINS.stream().sorted().forEach(name ->
                context.getSource().sendSuccess(() -> Component.literal(" §7- §f" + name), false)
            );
        }
        return 1;
    }

    private int cmdAdminsAdd(CommandContext<CommandSourceStack> context) {
        String name = StringArgumentType.getString(context, "name");

        if (ADMINS.add(name)) {
            saveAdmins();
            context.getSource().sendSuccess(() -> Component.literal("§aAdded " + name + " as admin"), true);
        } else {
            context.getSource().sendFailure(Component.literal(name + " is already an admin"));
        }
        return 1;
    }

    private int cmdAdminsRemove(CommandContext<CommandSourceStack> context) {
        String name = StringArgumentType.getString(context, "name");

        if (ADMINS.remove(name)) {
            saveAdmins();
            context.getSource().sendSuccess(() -> Component.literal("§aRemoved " + name + " from admins"), true);
        } else {
            context.getSource().sendFailure(Component.literal(name + " is not an admin"));
        }
        return 1;
    }

    private void loadConfig() {
        PROTECTED.clear();
        if (configFile == null || !Files.exists(configFile)) {
            PROTECTED.addAll(List.of("r1noa", "JGH_Play", "Stebii", "itzxthunder", "typixbrandy"));
            saveConfig();
            return;
        }
        try {
            String content = Files.readString(configFile).trim();
            if (content.startsWith("[") && content.endsWith("]")) {
                String inner = content.substring(1, content.length() - 1).trim();
                if (!inner.isEmpty()) {
                    int idx = 0;
                    while ((idx = inner.indexOf('"', idx)) >= 0) {
                        int start = idx + 1;
                        int end = inner.indexOf('"', start);
                        if (end >= start) {
                            PROTECTED.add(inner.substring(start, end));
                        }
                        idx = end + 1;
                    }
                }
            }
        } catch (IOException e) {
            System.err.println("[PlayerBlocker] Failed to load config: " + e.getMessage());
        }
    }

    private void saveConfig() {
        if (configFile == null) return;
        try {
            Files.createDirectories(configFile.getParent());
            String json = PROTECTED.stream()
                .map(name -> "\"" + name + "\"")
                .collect(Collectors.joining(",", "[", "]"));
            Files.writeString(configFile, json);
        } catch (IOException e) {
            System.err.println("[PlayerBlocker] Failed to save config: " + e.getMessage());
        }
    }

    private void loadAdmins() {
        ADMINS.clear();
        ADMINS.add("JGH_Play"); // default admin
        if (adminsFile == null || !Files.exists(adminsFile)) {
            saveAdmins();
            return;
        }
        try {
            String content = Files.readString(adminsFile).trim();
            if (content.startsWith("[") && content.endsWith("]")) {
                String inner = content.substring(1, content.length() - 1).trim();
                if (!inner.isEmpty()) {
                    int idx = 0;
                    while ((idx = inner.indexOf('"', idx)) >= 0) {
                        int start = idx + 1;
                        int end = inner.indexOf('"', start);
                        if (end >= start) {
                            ADMINS.add(inner.substring(start, end));
                        }
                        idx = end + 1;
                    }
                }
            }
        } catch (IOException e) {
            System.err.println("[PlayerBlocker] Failed to load admins: " + e.getMessage());
        }
    }

    private void saveAdmins() {
        if (adminsFile == null) return;
        try {
            Files.createDirectories(adminsFile.getParent());
            String json = ADMINS.stream()
                .map(name -> "\"" + name + "\"")
                .collect(Collectors.joining(",", "[", "]"));
            Files.writeString(adminsFile, json);
        } catch (IOException e) {
            System.err.println("[PlayerBlocker] Failed to save admins: " + e.getMessage());
        }
    }
}
