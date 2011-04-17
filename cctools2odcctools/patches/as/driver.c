--- ./driver.c.orig	2011-01-21 12:06:04.000000000 +0100
+++ ./driver.c	2011-01-21 12:06:58.000000000 +0100
@@ -27,26 +27,13 @@
 char **argv,
 char **envp)
 {
-    const char *LIB =
-#if defined(__OPENSTEP__) || defined(__HERA__) || \
-    defined(__GONZO_BUNSEN_BEAKER__) || defined(__KODIAK__)
-		    "../libexec/";
-#else
-		    "../libexec/gcc/darwin/";
-#endif
-    const char *LOCALLIB =
-#if defined(__OPENSTEP__) || defined(__HERA__) || \
-    defined(__GONZO_BUNSEN_BEAKER__) || defined(__KODIAK__)
-		    "../local/libexec/";
-#else
-		    "../local/libexec/gcc/darwin/";
-#endif
+    const char *LIB = ASLIBEXECDIR ;
     const char *AS = "/as";
 
     int i;
     uint32_t count, verbose;
     char *p, c, *arch_name, *as, *as_local;
-    char *prefix, buf[MAXPATHLEN], resolved_name[PATH_MAX];
+    char buf[MAXPATHLEN], resolved_name[PATH_MAX];
     unsigned long bufsize;
     struct arch_flag arch_flag;
     const struct arch_flag *arch_flags, *family_arch_flag;
@@ -57,19 +44,6 @@
 	/*
 	 * Construct the prefix to the assembler driver.
 	 */
-	bufsize = MAXPATHLEN;
-	p = buf;
-	i = _NSGetExecutablePath(p, &bufsize);
-	if(i == -1){
-	    p = allocate(bufsize);
-	    _NSGetExecutablePath(p, &bufsize);
-	}
-	prefix = realpath(p, resolved_name);
-	if(realpath == NULL)
-	    system_fatal("realpath(3) for %s failed", p);
-	p = rindex(prefix, '/');
-	if(p != NULL)
-	    p[1] = '\0';
 	/*
 	 * Process the assembler flags exactly like the assembler would (except
 	 * let the assembler complain about multiple flags, bad combinations of
@@ -178,7 +152,7 @@
 	    }
 
 	}
-	as = makestr(prefix, LIB, arch_name, AS, NULL);
+	as = makestr("", LIB, arch_name, AS, NULL);
 
 	/*
 	 * If this assembler exist try to run it else print an error message.
@@ -190,38 +164,19 @@
 	    else
 		exit(1);
 	}
-	as_local = makestr(prefix, LOCALLIB, arch_name, AS, NULL);
-	if(access(as_local, F_OK) == 0){
-	    argv[0] = as_local;
-	    if(execute(argv, verbose))
-		exit(0);
-	    else
-		exit(1);
-	}
 	else{
 	    printf("%s: assembler (%s or %s) for architecture %s not "
 		   "installed\n", progname, as, as_local, arch_name);
 	    arch_flags = get_arch_flags();
 	    count = 0;
 	    for(i = 0; arch_flags[i].name != NULL; i++){
-		as = makestr(prefix, LIB, arch_flags[i].name, AS, NULL);
+		as = makestr("", LIB, arch_flags[i].name, AS, NULL);
 		if(access(as, F_OK) == 0){
 		    if(count == 0)
 			printf("Installed assemblers are:\n");
 		    printf("%s for architecture %s\n", as, arch_flags[i].name);
 		    count++;
 		}
-		else{
-		    as_local = makestr(prefix, LOCALLIB, arch_flags[i].name,
-				       AS, NULL);
-		    if(access(as_local, F_OK) == 0){
-			if(count == 0)
-			    printf("Installed assemblers are:\n");
-			printf("%s for architecture %s\n", as_local,
-			       arch_flags[i].name);
-			count++;
-		    }
-		}
 	    }
 	    if(count == 0)
 		printf("%s: no assemblers installed\n", progname);
