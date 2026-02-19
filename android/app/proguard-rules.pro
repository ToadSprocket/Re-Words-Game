# Preserve annotations used by Tink and other crypto libs
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }

# javax.lang.model.element.Modifier is a JDK compiler-only class referenced
# by errorprone annotations; it does not exist on Android so R8 must ignore it.
-dontwarn javax.lang.model.element.Modifier
