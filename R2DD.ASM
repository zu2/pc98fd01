;;
;;	�o�b�X�W�O�P�^�o�b�Q�W�U��p
;;		���p�C���^�[�t�F�C�X�ɐڑ����ꂽ�e�c�c�̃��[�h��
;;		�Q�c�c��p�Ƃ���B
;;
;;		CopyRight (C) 1990  SHIN ZUKERAN.
;;
;;	�g�p���@�F
;;		r2DD �R�}���h���풓������ƁA�O���e�c�c�͂Q�c�c only �ƂȂ�܂�
;;	�풓�����F
;;		�풓���Ă����Ԃ� r2DD -r �Ƃ���ƁA�풓�������ł��܂��B
;;
;;	�풓�I�����͕��A�R�[�h�Ƃ��ĂO��Ԃ��C�풓�������͂P��Ԃ��
;;
;;
		name	r2DD		;; regident 2DD
DiskBiosVector	=	1Bh		;; Disk BIOS Vector for PC9801/PC286
;;
CODE		segment	word public
		assume	cs:CODE
		org	100H
Start:
		jmp	StartUp
;;
CLSIDLen	=	7
CLSID		db	'2DD TSR',0		;; �s�r�q�풓���ʎq
DiskBiosVecSave	dd	0			;; ���x�N�g���ۑ��̈�(CLS)
SAVE_AX		dw	0
SAVE_IP		dw	0
SAVE_CS		dw	0
;;
IntStart:					;; ���荞�݊J�n
		sti
		cmp	ax,6A92h
		jz	error_return
		cmp	ax,6A93h
		jz	error_return
		cmp	ax,0492h
		jz	mode_2dd
		cmp	ax,0493h
		jz	mode_2dd
		cmp	ax,8492h
		jz	status_2dd
		cmp	ax,8493h
		jz	status_2dd
		jmp	cs:[DiskBiosVecSave]
mode_2dd:
		and	ax,0ff1fh
		jmp	cs:[DiskBiosVecSave]
status_2dd:
		pushf
		call	cs:[DiskBiosVecSave]
		jc	status_end
		mov	cs:[SAVE_AX],AX
		pop	cs:[SAVE_IP]
		pop	cs:[SAVE_CS]
		pop	ax
		and	ax,0fffeh
		push	ax
		push	cs:[SAVE_CS]
		push	cs:[SAVE_IP]
		mov	ax,cs:[SAVE_AX]
		or	ah,08h
status_end:
		iret
;
error_return:
		pop	cx
		pop	dx
		pop	ax
		or	ax,0001h
		push	ax
		push	dx
		push	cx
		mov	ah,0e0h
		iret
;
		even
CLSEnd:
;;
;;
r2DDMes	db	'r2DD version 1.0'
		db	' CopyRight (C) 1990  SHIN ZUKERAN.'
		db	0DH,0AH,'$'
ResidentMes	db	0DH,0AH
		db	'�O�t���h���C�u�̃��[�h���Q�c�c�ɂ��Ă�������'
		db	0DH,0AH,'$'
RemoveMes	db	'�O�t���h���C�u�̃��[�h���Q�g�c�ɂ��Ă�������'
		db	0DH,0AH,'$'
AlreadyMes	db	'already resident.'
		db	0DH,0AH,'$'
NotResidentMes	db	'not resident.'
		db	0DH,0AH,'$'
UsageMes	db	'usage:r2DD [-?r]',0dh,0ah
		db	'option: -?   see this message.',0dh,0ah
		db	'        -r   remove r2DD from memory.',0dh,0ah
		db	'$'
HelpFlag	db	0
RemoveFlag	db	0
;;
StartUp		proc	near
		call	CheckArg		;; �p�����^�`�F�b�N
		cmp	[HelpFlag],0
		jz	NotUsage
		call	Usage
		jmp	Terminate
NotUsage:
		mov	al,DiskBiosVector		;; CLS ���荞�݃x�N�g���𓾂�
		mov	ah,35H
		int	21H			;; �� ES:BX �ɃA�h���X���Ԃ�
;;
;;	���ɏ풓���Ă��邩�ǂ����𒲂ׂ�
;;
		mov	si,offset CLSID	;; �s�r�q���ʎq�A�h���X
		mov	di,si
		cld
		sub	cx,cx			;; �[���t���O�̃N���A(�����K�v)
		mov	cx,CLSIDLen		;; 10������r����
;;
	repz	cmpsb				;; ��v�`�F�b�N
		jz	AlreadyResident
;;
		cmp	[RemoveFlag],0		;; -r �I�v�V�����̎w���?
		jz	ResidentCLS
		call	DispNotResidentMes
		jmp	Terminate
;;
;;	�V�K�ɏ풓������
;;
ResidentCLS:
		mov	word ptr [DiskBiosVecSave],bx
		mov	word ptr [DiskBiosVecSave+2],es
;;
		mov	dx,offset IntStart	;; DS:DX �� ���荞�݃A�h���X
		mov	al,DiskBiosVector		;; �s�r�q�Ƀt�b�N����
		mov	ah,25H
		int	21H
;;
		mov	dx,offset r2DDMes	;; �v���O�������\��
		mov	ah,9
		int	21h
;;
		mov	dx,offset ResidentMes	;; �풓���b�Z�[�W�o��
		mov	ah,9
		int	21h
;;
		mov	dx,offset CLSEnd	;; �풓�T�C�Y�����߂�B
		add	dx,000FH
		shr	dx,1			;; �p���O���t�P�ʂɐ؂�グ
		shr	dx,1
		shr	dx,1
		shr	dx,1
		mov	ax,3100H		;; �풓�I��(���A�R�[�h 0 )
		int	21H			
;;
;;	�풓�ς̂Ƃ�
;;
AlreadyResident:
		cmp	[RemoveFlag],0
		jnz	RemoveCLS
		call	DispAlreadyMes
		jmp	short Terminate
;;
;;	�풓��������
;;
RemoveCLS:
		push	es
		mov	es,es:[2ch]		;; PSP������A�h���X�𓾂�
		mov	ah,49h			;; ���������u���b�N�̉��
		int	21h
		pop	es			;; ES=�풓�v���O������PSP
		mov	ah,49h			;; �s�r�q�������u���b�N�̉��
		int	21h
;;
		push	ds
		lds	dx,ES:[DiskBiosVecSave]	;; DS:DX �� ���荞�݃A�h���X
		mov	al,DiskBiosVector		;; ���̊��荞�݂ɖ߂�
		mov	ah,25H
		int	21H
		pop	ds
;;
		mov	dx,offset r2DDMes	;; �v���O�������\��
		mov	ah,9
		int	21h
;;
		mov	dx,offset RemoveMes	;; �풓�������b�Z�[�W�o��
		mov	ah,9
		int	21h
;;
Terminate:
		mov	ax,4c01h		;; ��풓�I��(���A�R�[�h 1 )
		int	21H			
;;
;;	�R�}���h���C���p�����^�̃`�F�b�N
;;		-r & -?
CheckArg:
		mov	bx,0080h
CheckArg1:	inc	bx
		mov	ax,[bx]
		cmp	al,0dh
		jz	CheckArg9
		cmp	al,20h
		jbe	CheckArg1
		cmp	ax,'?-'
		jnz	CheckArg2
		mov	[HelpFlag],1
		inc	bx
		jmp	short CheckArg1
CheckArg2:	or	al,20h			;; tolower
		cmp	ax,'r-'
		jnz	CheckArg3
		mov	[RemoveFlag],1
		inc	bx
		jmp	short CheckArg1
CheckArg3:	mov	[HelpFlag],1
		inc	bx
		jmp	short CheckArg1
CheckArg9:	ret
;;
;;
;;	Help �\��
;;
Usage:
		mov	dx,offset r2DDMes	;; �v���O�������\��
		mov	ah,9
		int	21h
;;
		mov	dx,offset UsageMes	;; �풓�������b�Z�[�W�o��
		mov	ah,9
		int	21h
;;
		ret
;;
;;	�풓�σ��b�Z�[�W�\��
;;
DispAlreadyMes:
		mov	dx,offset r2DDMes	;; �v���O�������\��
		mov	ah,9
		int	21h
;;
		mov	dx,offset AlreadyMes	;; �풓�σ��b�Z�[�W�o��
		mov	ah,9
		int	21h
;;
		ret
;;
;;	��풓���b�Z�[�W�\��
;;
DispNotResidentMes:
		mov	dx,offset r2DDMes	;; �v���O�������\��
		mov	ah,9
		int	21h
;;
		mov	dx,offset NotResidentMes ;; �����s���b�Z�[�W�o��
		mov	ah,9
		int	21h
;;
		ret
;;
StartUp		endp
;;
CODE		ends
		end	Start