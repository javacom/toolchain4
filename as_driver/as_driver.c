#include <stdio.h>
#include <string.h>

static char __signature[] = "as_driver. (C) Denis Froschauer 2011";

struct S_prg {
	char	*arch;
	char	*prg;
};

struct S_prg asTab[] = {
	"i686", "/usr/bin/i686-linux-gnu-as",
	"arm", "/usr/bin/arm-apple-darwin9-as",
	NULL
};

struct S_prg ldTab[] = {
	"i686", "/usr/bin/i686-linux-gnu-ld",
	"arm", "/usr/bin/arm-apple-darwin9-ld",
	NULL
};

int verbose = 0;

main(int ac, char **av)
{
	int	i;
	char	*arch = "i686";

	arch	= "i686";

	for	(i=1; i<ac; i++)
	{
		if	(!strcmp(av[i], "-arch"))
			arch	= av[i+1];
		else if	(!strcmp(av[i], "-v"))
			verbose	= 1;
		else if	(!strcmp(av[i], "-V"))
			verbose	= 1;
		else if	(!strcmp(av[i], "--verbose"))
			verbose	= 1;
	}

	if	(verbose)
	{
		printf ("asld_driver. Supported architectures : ");
		for	(i=0; asTab[i].arch; i++)
			printf ("%s ", asTab[i].arch);
		printf ("\nasld_driver called with :\n");
		for	(i=0; i<ac; i++)
			printf ("\targ %d : %s\n", i, av[i]);
	}

	if	(strstr(av[0], "ld"))
		return execPrg(ldTab, arch, av);

	//	Default is 'as'
	return execPrg(asTab, arch, av);
}

int execPrg(struct S_prg *prgTab, char *sel, char **av)
{
	int	i;

	for	(i=0; prgTab[i].arch; i++)
	{
		if	(strstr(sel, prgTab[i].arch))
		{
			if	(verbose)
				printf ("Launching %s\n", prgTab[i].prg);
			return execvp (prgTab[i].prg, av);
		}
	}
	return	-1;
}
