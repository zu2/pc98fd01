/*
 *	発想を変えた FDSET.c	version 2.0
 *
 *		(C) zukkun 1990.
 */

#include	<stdio.h>
#include	<stdlib.h>
#include	<dos.h>
#include	<string.h>

static	void	mode_set( int, int );
static	void	pokeb( unsigned int seg, unsigned int off, int value );

extern	void
main( int argc,	char **argv )
{
	if( argc==2 && stricmp(argv[1],"-d")==0 ){
		mode_set( 0x90,0x10 );
	}else if( argc==2 && stricmp(argv[1],"-h")==0 ){
		mode_set( 0x10,0x90 );
	}

	/* 以下の poke 文の羅列は xform（いとぢゅん様作成）を参考にしました */
	pokeb( 0x0000, 0x0564, 0xc0 );		/* 2HD & dual */
	pokeb( 0x0000, 0x056c, 0xc0 );
	pokeb( 0x0000, 0x0574, 0xc0 );
	pokeb( 0x0000, 0x057c, 0xc0 );
	pokeb( 0x0000, 0x05d8, 0xc0 );		/* 2DD */
	pokeb( 0x0000, 0x05da, 0xc0 );
	pokeb( 0x0000, 0x05dc, 0xc0 );
	pokeb( 0x0000, 0x05de, 0xc0 );
	bdos( 0x0D, 0x00, 0x00 );	/* Disk Reset */

	exit( 0 );
}

static	void
mode_set( int mode1, int mode2 )
{
	char far *adrs;

	adrs = MK_FP( 0x0060, 0x1766 );

	if( ((*adrs)&0xf0) == mode1 ){
		*adrs = mode2 | ( *adrs&0x0f );
	}
	adrs++;
	if( ((*adrs)&0xf0) == mode1 ){
		*adrs = mode2 | ( *adrs&0x0f );
	}
}

static	void
pokeb( unsigned int seg, unsigned int off, int value )
{
	char	far *adrs;

	adrs = MK_FP( seg, off );
	*adrs = value;
}
