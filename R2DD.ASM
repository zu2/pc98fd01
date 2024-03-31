;;
;;	ＰＣ９８０１／ＰＣ２８６専用
;;		両用インターフェイスに接続されたＦＤＤのモードを
;;		２ＤＤ専用とする。
;;
;;		CopyRight (C) 1990  SHIN ZUKERAN.
;;
;;	使用方法：
;;		r2DD コマンドを常駐させると、外部ＦＤＤは２ＤＤ only となります
;;	常駐解除：
;;		常駐している状態で r2DD -r とすると、常駐を解除できます。
;;
;;	常駐終了時は復帰コードとして０を返し，常駐解除時は１を返す｡
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
CLSID		db	'2DD TSR',0		;; ＴＳＲ常駐識別子
DiskBiosVecSave	dd	0			;; 旧ベクトル保存領域(CLS)
SAVE_AX		dw	0
SAVE_IP		dw	0
SAVE_CS		dw	0
;;
IntStart:					;; 割り込み開始
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
		db	'外付けドライブのモードを２ＤＤにしてください'
		db	0DH,0AH,'$'
RemoveMes	db	'外付けドライブのモードを２ＨＤにしてください'
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
		call	CheckArg		;; パラメタチェック
		cmp	[HelpFlag],0
		jz	NotUsage
		call	Usage
		jmp	Terminate
NotUsage:
		mov	al,DiskBiosVector		;; CLS 割り込みベクトルを得る
		mov	ah,35H
		int	21H			;; → ES:BX にアドレスが返る
;;
;;	既に常駐しているかどうかを調べる
;;
		mov	si,offset CLSID	;; ＴＳＲ識別子アドレス
		mov	di,si
		cld
		sub	cx,cx			;; ゼロフラグのクリア(多分必要)
		mov	cx,CLSIDLen		;; 10文字比較する
;;
	repz	cmpsb				;; 一致チェック
		jz	AlreadyResident
;;
		cmp	[RemoveFlag],0		;; -r オプションの指定は?
		jz	ResidentCLS
		call	DispNotResidentMes
		jmp	Terminate
;;
;;	新規に常駐させる
;;
ResidentCLS:
		mov	word ptr [DiskBiosVecSave],bx
		mov	word ptr [DiskBiosVecSave+2],es
;;
		mov	dx,offset IntStart	;; DS:DX ← 割り込みアドレス
		mov	al,DiskBiosVector		;; ＴＳＲにフックする
		mov	ah,25H
		int	21H
;;
		mov	dx,offset r2DDMes	;; プログラム名表示
		mov	ah,9
		int	21h
;;
		mov	dx,offset ResidentMes	;; 常駐メッセージ出力
		mov	ah,9
		int	21h
;;
		mov	dx,offset CLSEnd	;; 常駐サイズを求める。
		add	dx,000FH
		shr	dx,1			;; パラグラフ単位に切り上げ
		shr	dx,1
		shr	dx,1
		shr	dx,1
		mov	ax,3100H		;; 常駐終了(復帰コード 0 )
		int	21H			
;;
;;	常駐済のとき
;;
AlreadyResident:
		cmp	[RemoveFlag],0
		jnz	RemoveCLS
		call	DispAlreadyMes
		jmp	short Terminate
;;
;;	常駐解除する
;;
RemoveCLS:
		push	es
		mov	es,es:[2ch]		;; PSPから環境アドレスを得る
		mov	ah,49h			;; 環境メモリブロックの解放
		int	21h
		pop	es			;; ES=常駐プログラムのPSP
		mov	ah,49h			;; ＴＳＲメモリブロックの解放
		int	21h
;;
		push	ds
		lds	dx,ES:[DiskBiosVecSave]	;; DS:DX ← 割り込みアドレス
		mov	al,DiskBiosVector		;; 元の割り込みに戻す
		mov	ah,25H
		int	21H
		pop	ds
;;
		mov	dx,offset r2DDMes	;; プログラム名表示
		mov	ah,9
		int	21h
;;
		mov	dx,offset RemoveMes	;; 常駐解除メッセージ出力
		mov	ah,9
		int	21h
;;
Terminate:
		mov	ax,4c01h		;; 非常駐終了(復帰コード 1 )
		int	21H			
;;
;;	コマンドラインパラメタのチェック
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
;;	Help 表示
;;
Usage:
		mov	dx,offset r2DDMes	;; プログラム名表示
		mov	ah,9
		int	21h
;;
		mov	dx,offset UsageMes	;; 常駐解除メッセージ出力
		mov	ah,9
		int	21h
;;
		ret
;;
;;	常駐済メッセージ表示
;;
DispAlreadyMes:
		mov	dx,offset r2DDMes	;; プログラム名表示
		mov	ah,9
		int	21h
;;
		mov	dx,offset AlreadyMes	;; 常駐済メッセージ出力
		mov	ah,9
		int	21h
;;
		ret
;;
;;	非常駐メッセージ表示
;;
DispNotResidentMes:
		mov	dx,offset r2DDMes	;; プログラム名表示
		mov	ah,9
		int	21h
;;
		mov	dx,offset NotResidentMes ;; 解除不可メッセージ出力
		mov	ah,9
		int	21h
;;
		ret
;;
StartUp		endp
;;
CODE		ends
		end	Start
