package mhv.test;

import java.lang.reflect.*;
import java.util.Set;
import java.util.concurrent.Executor;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.loader.api.FabricLoader;

/** Test-only mod. Not included in the delivered JAR; runs in a disposable game directory. */
public final class SmokeTest implements ClientModInitializer {
    @Override public void onInitializeClient() {
        try {
            Class<?> listener = Class.forName("net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents$ClientStarted");
            Object event = Class.forName("net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents")
                .getField("CLIENT_STARTED").get(null);
            Object proxy = Proxy.newProxyInstance(listener.getClassLoader(), new Class<?>[]{listener}, (p, m, args) -> {
                if (m.getName().equals("onClientStarted")) {
                    Object client = args[0];
                    try { verify(); System.out.println("MHV_SMOKE_PASS: client started and compatibility regression checks passed"); }
                    catch (Throwable ex) { System.out.println("MHV_SMOKE_FAIL"); ex.printStackTrace(); }
                    new Thread(() -> {
                        try {
                            Thread.sleep(20000);
                            ((Executor) client).execute(() -> {
                                try {
                                    Object screen = client.getClass().getField("field_1755").get(client);
                                    Object overlay = client.getClass().getMethod("method_18506").invoke(client);
                                    if (overlay == null && screen != null && Class.forName("net.minecraft.class_442").isInstance(screen)) {
                                        System.out.println("MHV_MENU_PASS: title screen reached, resource loading complete");
                                    } else {
                                        System.out.println("MHV_MENU_STATE: screen=" + (screen == null ? "null" : screen.getClass().getName())
                                            + ", overlay=" + (overlay == null ? "null" : overlay.getClass().getName()));
                                    }
                                    client.getClass().getMethod("method_1490").invoke(client);
                                }
                                catch (Exception ex) { ex.printStackTrace(); }
                            });
                        } catch (InterruptedException ex) { Thread.currentThread().interrupt(); }
                    }, "mhv-smoke-shutdown").start();
                }
                return null;
            });
            Class.forName("net.fabricmc.fabric.api.event.Event").getMethod("register", Object.class).invoke(event, proxy);
        } catch (Exception ex) { throw new RuntimeException(ex); }
    }

    private static Object call(Object target, String name, Class<?>[] types, Object... args) throws Exception {
        return target.getClass().getMethod(name, types).invoke(target, args);
    }
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    private static void verify() throws Exception {
        var loader = FabricLoader.getInstance();
        boolean axiom = Boolean.getBoolean("mhv.test.axiom");
        check(loader.isModLoaded("axiom") == axiom, "Axiom fixture mismatch");
        check(loader.isModLoaded("opsec_mhv") && !loader.isModLoaded("opsec"), "Fork identity");
        Class<?> settingsType = Class.forName("aurick.opsec.mod.config.SpoofSettings");
        Class<?> modeType = Class.forName("aurick.opsec.mod.config.SpoofSettings$WhitelistMode");
        Class<?> registry = Class.forName("aurick.opsec.mod.tracking.ModRegistry");
        Class<?> configType = Class.forName("aurick.opsec.mod.config.OpsecConfig");
        Object config = configType.getMethod("getInstance").invoke(null);
        Object settings = call(config, "getSettings", new Class<?>[]{});
        Object snapshot = settingsType.getConstructor().newInstance();
        call(snapshot, "copyFrom", new Class<?>[]{settingsType}, settings);
        try {
            // Exercise old saved configurations that requested full vanilla spoofing.
            Object json = Class.forName("com.google.gson.JsonParser").getMethod("parseString", String.class)
                .invoke(null, "{\"spoofAsVanilla\":true,\"whitelistMode\":\"OFF\"}");
            Object jsonObject = call(json, "getAsJsonObject", new Class<?>[]{});
            Object legacy = settingsType.getMethod("fromJson", Class.forName("com.google.gson.JsonObject")).invoke(null, jsonObject);
            check((boolean)call(legacy, "isSpoofAsVanilla", new Class<?>[]{}) == !axiom, "legacy vanilla mode guard");
            check((boolean)call(legacy, "isFabricMode", new Class<?>[]{}) == axiom, "effective Fabric mode");
            check((boolean)call(legacy, "isWhitelistEnabled", new Class<?>[]{}) == axiom, "legacy whitelist guard");
            check(call(legacy, "getEffectiveBrand", new Class<?>[]{}).equals(axiom ? "fabric" : "vanilla"), "effective brand");
            call(settings, "setSpoofAsVanilla", new Class<?>[]{boolean.class}, false);
            Object custom = modeType.getField("CUSTOM").get(null);
            call(settings, "setWhitelistMode", new Class<?>[]{modeType}, custom);
            call(settings, "setWhitelistedMods", new Class<?>[]{Set.class}, new java.util.HashSet<String>());
            registry.getMethod("rebuildDependencyClosure").invoke(null);
            Method channelCheck = java.util.Arrays.stream(registry.getMethods())
                .filter(m -> m.getName().equals("isWhitelistedChannel")).findFirst().orElseThrow();
            Class<?> identifier = channelCheck.getParameterTypes()[0];
            Method factory = java.util.Arrays.stream(identifier.getMethods())
                .filter(m -> Modifier.isStatic(m.getModifiers()) && m.getReturnType() == identifier
                    && java.util.Arrays.equals(m.getParameterTypes(), new Class<?>[]{String.class, String.class}))
                .findFirst().orElseThrow();
            check((boolean)channelCheck.invoke(null, factory.invoke(null, "axiom", "mhv_test")) == axiom, "Axiom late channel allowed only when loaded");
            check(!(boolean)channelCheck.invoke(null, factory.invoke(null, "mhv_unrelated", "blocked")), "unrelated channels stay blocked");
            registry.getMethod("recordTranslationKey", String.class, String.class).invoke(null, "axiom", "axiom.mhv.test");
            check((boolean)registry.getMethod("isWhitelistedTranslationKey", String.class).invoke(null, "axiom.mhv.test") == axiom, "Axiom translation whitelist");
            if (axiom) {
                for (String id : new String[]{"axiom", "com_moulberry_axiomclientapi", "lattice"}) {
                    check((boolean)registry.getMethod("isInDependencyClosure", String.class).invoke(null, id), "Axiom dependency: " + id);
                }
                call(settings, "setSpoofAsVanilla", new Class<?>[]{boolean.class}, true);
                check(!(boolean)call(settings, "isSpoofAsVanilla", new Class<?>[]{}), "UI cannot re-enable vanilla spoofing with Axiom");
            }
        } finally {
            call(settings, "copyFrom", new Class<?>[]{settingsType}, snapshot);
            registry.getMethod("rebuildDependencyClosure").invoke(null);
        }
    }
}
