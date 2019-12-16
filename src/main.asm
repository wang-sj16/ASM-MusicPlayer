.386

.model	flat, stdcall
option	casemap :none

;include files
INCLUDE	windows.inc
INCLUDE	user32.inc
INCLUDE	kernel32.inc
INCLUDE	comctl32.inc	
INCLUDE	winmm.inc
INCLUDE	comdlg32.inc
INCLUDE	msvcrt.inc
INCLUDE shlwapi.inc
INCLUDE msvcrt.inc
INCLUDE gdi32.inc
INCLUDE gdiplus.inc
INCLUDE wsock32.inc

;include libs
INCLUDELIB shlwapi.lib
INCLUDELIB user32.lib
INCLUDELIB kernel32.lib
INCLUDELIB comctl32.lib
INCLUDELIB winmm.lib
INCLUDELIB msvcrt.lib
INCLUDELIB comdlg32.lib
INCLUDELIB gdi32.lib
INCLUDELIB gdiplus.lib
INCLUDELIB wsock32.lib

;function declaration
main_proc	PROTO	:DWORD,:DWORD,:DWORD,:DWORD
init	PROTO :DWORD
handle_exit		PROTO :DWORD
open_song		PROTO:DWORD, :DWORD
alter_song		PROTO :DWORD, :DWORD
handle_add_btn	PROTO :DWORD
handle_dele_btn PROTO :DWORD
handle_play_btn	PROTO :DWORD
alter_volume	PROTO :DWORD
show_volume		PROTO :DWORD
read_lrc_file	PROTO:DWORD, :DWORD
show_lrc		PROTO:DWORD
handle_time_slider		PROTO  :DWORD
alter_time				PROTO  :DWORD
switch_next_song		PROTO  :DWORD
handle_silence_btn		PROTO : DWORD
handle_recycle_btn		PROTO : DWORD

;歌曲结构体
Song STRUCT
	music_name BYTE 100 DUP(0);歌曲名
	music_path BYTE 100 DUP(0);歌曲路径
Song ends

;lrc歌词结构体
Lyric STRUCT
	content BYTE 100 DUP(0);歌词内容
	time DWORD 0;歌词开始时间
Lyric ends

.const
	IMG_LOGO	EQU	200
	IMG_START	EQU	300
	IMG_PAUSE	EQU	301
	IMG_OPEN_SOUND	EQU	304
	IMG_CLOSE_SOUND	EQU	305
	IMG_RECYCLE		EQU	306
	IMG_SINGLE		EQU	307
	IMG_RANDOM		EQU	308

	IDD_MAIN			EQU 1000
	IDB_EXIT			EQU 1001
	IDC_paly_btn		EQU 1100;播放按钮
	IDC_time_slider		EQU 1101;时间进度条
	IDC_vol_slider		EQU 1102;音量
	IDC_song_menu		EQU 1103;歌单列表
	IDC_vol_txt			EQU 1104;音量显示
	IDC_time_txt		EQU 1105;进度显示
	
	IDC_prev_btn		EQU 1200;上一首歌
	IDC_next_btn		EQU 1201;下一首歌
	IDC_backward		EQU 1203;快退
	IDC_forward			EQU 1204;快进
	
	IDC_add_music_btn		EQU 1205;载入歌曲
	IDC_dele_btn			EQU 1206;删除歌曲
	IDC_silence_btn			EQU 1207;静音按钮
	IDC_recycle_btn			EQU 1208;循环模式按钮
	IDC_lyrics_current		EQU 1220;歌词显示
	IDC_lyrics_prev1		EQU 1221;歌词显示
	IDC_lyrics_next1		EQU 1222;歌词显示
	IDC_lyrics_prev2		EQU 1223;歌词显示
	IDC_lyrics_next2		EQU 1224;歌词显示
	IDC_lyrics_board		EQU 1225

	SINGLE_REPEAT		EQU 0;单曲循环
	LIST_REPEAT			EQU 1;列表循环
	RANDOM_REPEAT		EQU 2;随机循环

	STOP_MUSIC		EQU 0;停止播放
	PLAY_MUSIC		EQU 1;正在播放
	PAUSE_MUSIC		EQU 2;暂停播放

	WM_SHELLNOTIFY    	EQU WM_USER+5 
	
.data	
	;--------mci命令--------
	cmd_open BYTE 'open "%s" alias my_song type mpegvideo',0
	cmd_close BYTE "close my_song",0
	cmd_play BYTE "play my_song", 0	
	cmd_pause BYTE "pause my_song",0
	cmd_resume BYTE "resume my_song",0
	cmd_getLen BYTE "status my_song length", 0
	cmd_getPos BYTE "status my_song position", 0
	cmd_setPos BYTE "seek my_song to %d", 0
	cmd_setStart BYTE "seek my_song to start", 0	
	cmd_setVol BYTE "setaudio my_song volume to %d",0
	;--------mci命令--------

	list_name BYTE "\\song.txt",0 ;歌单文件

	;--------当前歌曲信息--------
	current_len BYTE 32 dup(0)
	current_len_minute DWORD 0
	current_len_second DWORD 0

	current_pos BYTE 32 dup(0)
	current_pos_minute DWORD 0
	current_pos_second DWORD 0	

	current_index DWORD 0;当前歌曲在歌单中的下标
	;--------当前歌曲信息--------

	;--------格式设置信息--------
	scale_second DWORD 1000		;秒转毫秒用
	scale_minute DWORD 60		;分钟转秒用	
	int_fmt BYTE '%d',0	
	time_fmt BYTE "%d:%d/%d:%d", 0	;时间显示格式
	;--------格式设置信息--------

	;--------状态模式信息--------
	dragging DWORD 0	;是否正在拖动进度条，0-否，1-是
	repeat_mode BYTE 0	;循环模式：单曲/列表/随机
	play_state BYTE 0	;播放状态：停止/播放/暂停	
	have_sound BYTE 1	;是否有声音
	;--------状态模式信息--------

	;歌单信息
	song_menu Song 100 dup(<"1", "1">)
	song_menu_size DWORD 0  ;歌单大小
	
	;------打开文件对话框信息------
	open_file_dlg OPENFILENAME <>
	dlg_title BYTE '选择播放音乐', 0	
	dlg_warning_title BYTE '警告', 0
	dlg_warning BYTE '请选择要删除的歌曲！', 0
	dlg_init_dir BYTE '\\', 0
	dlg_open_file_names BYTE 8000 DUP(0)
	dlg_file_name BYTE 100 DUP(0)
	dlg_path BYTE 100 DUP(0)
	dlg_nmax_file = SIZEOF dlg_open_file_names
	dlg_base_dir BYTE 256 DUP(0)
	sep BYTE '\\'
	;------打开文件对话框信息------

	;--------歌词信息--------
	lrc_array Lyric 500 dup(<>) ;歌词数组
	lrc_lines dword 0 ;歌词的行数
	
	lrc_addr dword 1000 dup(0)	;每句歌词地址
	lrc_time dword 1000 dup(0)	;歌词对应的时间
	cur_lrc_index dword 0	;当前歌词index
	lyric_line_total dword 0;总行数
	
	lrc_next_sentence byte "[", 0
	has_lyric byte 0;是否搜索到歌词
	none_lrc_txt byte "无歌词的纯音乐，或者歌词文件迷路了^_^",0
	empty_lrc byte "^_^",0
	long_str byte 1000 dup(0)
	dot_lrc byte ".lrc", 0
	point byte ".", 0
	lrc_buffer byte 200000 dup(0)
	lrc_file byte 2000 dup(0)
	actual_read_bytes dword 0
	lrc_prepare byte "- - - - - - - -",0
	;--------歌词信息--------

.data?
	hInstance	dd	?
	mci_cmd BYTE ?; mci控制命令
.code
start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke	InitCommonControls
	;从rc文件模板初始化
	invoke	DialogBoxParam, hInstance, IDD_MAIN, 0, offset main_proc, 0
	invoke	ExitProcess, eax

;##################################################
; 主过程函数
;##################################################
main_proc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	LOCAL wc:WNDCLASSEX 
	LOCAL current_slider:DWORD	
	.if	uMsg == WM_CLOSE		;退出程序
		invoke handle_exit, hWin
	.elseif	uMsg == WM_INITDIALOG	;初始化窗口
    	mov   wc.style, CS_HREDRAW or CS_DBLCLKS or CS_VREDRAW
    	invoke RegisterClassEx, addr wc ;注册窗口
		invoke init, hWin
		invoke	LoadIcon,hInstance,IMG_LOGO
		invoke	SendMessage, hWin, WM_SETICON, 1, eax  ;设置图标

	.elseif uMsg == WM_TIMER	;计时器消息
		.if play_state == PLAY_MUSIC
			invoke handle_time_slider, hWin	;刷新进度条
			invoke show_lrc, hWin			;刷新歌词
			invoke switch_next_song, hWin	;检查是否完成并切换歌曲
		.endif

	.elseif uMsg == WM_COMMAND ;按键命令
		mov	eax,wParam
		.if	ax == IDB_EXIT
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif ax == IDC_add_music_btn	;按下导入歌曲键
			invoke handle_add_btn, hWin
		.elseif song_menu_size == 0	;若干歌单为空,其余按钮无效
			ret 
		.elseif ax == IDC_song_menu  ;选中歌单元素
			shr eax,16
			.if ax == LBN_SELCHANGE	;选中项发生改变
				invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_GETCURSEL, 0, 0	;获取当前选中index
				invoke alter_song,hWin,eax	;改变播放歌曲
			.endif
		.elseif ax == IDC_paly_btn	;播放/暂停
			invoke handle_play_btn, hWin
		.elseif ax == IDC_prev_btn		;前一首歌
			.if current_index == 0
				mov eax, song_menu_size
				mov current_index,eax
			.endif
			dec current_index
			invoke SendDlgItemMessage,hWin, IDC_song_menu, LB_SETCURSEL, current_index, 0
			invoke alter_song,hWin,current_index
		.elseif ax == IDC_next_btn;若点击下一首歌
			inc current_index
			mov eax, current_index
			.if eax == song_menu_size
				mov current_index,0
			.endif
			invoke SendDlgItemMessage,hWin, IDC_song_menu, LB_SETCURSEL, current_index, 0
			invoke alter_song,hWin,current_index
		.elseif ax == IDC_backward	 ;若点击快退			
			.if play_state == 1		;当前为播放状态
				invoke mciSendString, addr cmd_getPos, addr current_pos, 32, NULL	;获取当前播放位置
				invoke StrToInt, addr current_pos	;当前进度转成int
				mov edi, eax
				.if edi < 5000  ;5秒以内返回开头，否则回退5秒
					mov edi, 0
				.else
					add edi, -5000
				.endif
				invoke SendDlgItemMessage, hWin, IDC_time_slider, TBM_SETPOS, 1, edi
				invoke wsprintf, addr mci_cmd, addr cmd_setPos, edi		;设置mci_cmd格式
				invoke mciSendString, addr mci_cmd, NULL, 0, NULL	
				invoke mciSendString, addr cmd_play, NULL, 0, NULL
			.endif
		.elseif ax == IDC_forward	;若点击快进			
			.if play_state == 1	;当前为播放状态
				invoke mciSendString, addr cmd_getPos, addr current_pos, 32, NULL	;获取当前播放位置
				invoke StrToInt, addr current_pos	;当前进度转成int
				mov edi, eax
				add edi, 5000	;快进5秒
				invoke SendDlgItemMessage, hWin, IDC_time_slider, TBM_SETPOS, 1, edi
				invoke wsprintf, addr mci_cmd, addr cmd_setPos, edi		;设置mci_cmd格式
				invoke mciSendString, addr mci_cmd, NULL, 0, NULL	
				invoke mciSendString, addr cmd_play, NULL, 0, NULL
			.endif
		.elseif ax == IDC_silence_btn	;按下静音按钮
			invoke handle_silence_btn,hWin
		.elseif ax == IDC_recycle_btn	;按下循环按钮
			invoke handle_recycle_btn,hWin		
		.elseif ax == IDC_dele_btn	;按下删除按钮
			invoke handle_dele_btn, hWin
		.endif

	.elseif uMsg == WM_HSCROLL		;滚动条消息
		invoke GetDlgCtrlID,lParam
		mov current_slider,eax	;储存当前滚动控件
		mov ax,WORD PTR wParam
		.if current_slider == IDC_vol_slider
			.if ax == SB_THUMBTRACK		;滚动消息
				invoke alter_volume,hWin
				invoke show_volume, hWin
			.endif
		.elseif current_slider == IDC_time_slider
			.if ax == SB_THUMBTRACK		;滚动中
				mov dragging, 1
			.elseif ax == SB_ENDSCROLL	;滚动结束
				mov dragging, 0
				invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_GETCURSEL, 0, 0	;获取播放列表中选中项目
				.if eax != -1
					invoke alter_time, hWin
				.endif
			.endif
		.endif
	.endif
	mov	eax, 0
	ret
main_proc endp

;##################################################
; 一些初始化设置
;##################################################
init proc hWin:DWORD

	LOCAL hFile: DWORD
	LOCAL bytes_read: DWORD

	;读取歌单
	invoke crt__getcwd, ADDR dlg_base_dir, SIZEOF dlg_base_dir
	invoke lstrcpy, ADDR dlg_file_name, ADDR dlg_base_dir
	invoke lstrcat, ADDR dlg_file_name, ADDR list_name
	invoke CreateFile, ADDR dlg_file_name, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
	mov hFile, eax
	.if hFile == INVALID_HANDLE_VALUE
		mov song_menu_size, 0
	.else
		invoke ReadFile, hFile, ADDR song_menu_size, SIZEOF song_menu_size, ADDR bytes_read, NULL
		.if bytes_read != SIZEOF song_menu_size
			mov song_menu_size, 0
		.else
			invoke ReadFile, hFile, ADDR song_menu, SIZEOF song_menu, ADDR bytes_read, NULL
			.if bytes_read != SIZEOF song_menu
				mov song_menu_size, 0
			.endif
		.endif
	.endif
	invoke CloseHandle, hFile

	;在空间中显示歌单
	mov ecx, song_menu_size
	mov esi, offset song_menu
	.if ecx > 0
		L1:
			push ecx
			invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_ADDSTRING, 0, ADDR (Song PTR [esi]).music_name
			add esi, TYPE song_menu
			pop ecx
		loop L1
	.endif
		
	;0.2 秒刷新一次
	invoke SetTimer, hWin, 1, 200, NULL
	
	;播放器ICON
	mov eax, IMG_START
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_paly_btn, BM_SETIMAGE, IMAGE_ICON, eax
	
	;循环播放ICON
	mov repeat_mode,LIST_REPEAT
	mov eax, IMG_RECYCLE
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_recycle_btn, BM_SETIMAGE, IMAGE_ICON, eax	
	
	;静音按钮ICON
	mov have_sound, 1
	mov eax, IMG_OPEN_SOUND
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_silence_btn, BM_SETIMAGE, IMAGE_ICON, eax

	;初始化音量条
	invoke SendDlgItemMessage, hWin, IDC_vol_slider, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, hWin, IDC_vol_slider, TBM_SETRANGEMAX, 0, 1000
	invoke SendDlgItemMessage, hWin, IDC_vol_slider, TBM_SETPOS, 1, 1000
	Ret
init endp


;##################################################
; 处理关闭
;##################################################
handle_exit proc hWin:DWORD
	LOCAL hFile: HANDLE
	LOCAL bytes_written: DWORD
	;关闭播放歌曲
	.if play_state != STOP_MUSIC
		invoke mciSendString, ADDR cmd_close, NULL, 0, NULL
	.endif

	;保存歌单
	invoke lstrcat, ADDR dlg_base_dir, ADDR list_name
	invoke CreateFile, ADDR dlg_base_dir, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov hFile, eax
	.if hFile != INVALID_HANDLE_VALUE
		invoke WriteFile, hFile, ADDR song_menu_size, SIZEOF song_menu_size, ADDR bytes_written, NULL
		invoke WriteFile, hFile, ADDR song_menu, SIZEOF song_menu, ADDR bytes_written, NULL
		invoke CloseHandle, hFile
	.endif

	;关闭对话框
	invoke	EndDialog, hWin, 0
	ret
handle_exit endp

;##################################################
; 读取mp3文件目录下的lrc文件
;##################################################
read_lrc_file proc hWin:DWORD, index:DWORD
	local hFile:DWORD
	local dscale:DWORD
	local offs:DWORD
	local times:DWORD
	local current_time:DWORD

	mov lrc_lines, 0
	mov offs, 48
	
	mov eax, index
	mov ebx, type song_menu
	mul ebx
	invoke lstrcpy,addr lrc_file,addr song_menu[eax].music_path
	invoke StrRStrI,addr lrc_file, NULL, addr point
	mov esi, eax
	invoke lstrcpy,esi, addr dot_lrc	;根据mp3文件找到lrc文件
	
	;读取lrc文件
	invoke CreateFile,addr lrc_file,GENERIC_READ,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	mov hFile, eax
	.if hFile == INVALID_HANDLE_VALUE	;打开失败
		mov has_lyric, byte ptr 0		;状态：无lrc
		invoke SendDlgItemMessage, hWin, IDC_lyrics_current, WM_SETTEXT, 0, addr none_lrc_txt
		invoke SendDlgItemMessage, hWin, IDC_lyrics_prev1, WM_SETTEXT, 0, addr empty_lrc
		invoke SendDlgItemMessage, hWin, IDC_lyrics_prev2, WM_SETTEXT, 0, addr empty_lrc
		invoke SendDlgItemMessage, hWin, IDC_lyrics_next1, WM_SETTEXT, 0, addr empty_lrc
		invoke SendDlgItemMessage, hWin, IDC_lyrics_next2, WM_SETTEXT, 0, addr empty_lrc
	.else	;解析lrc
		mov has_lyric, byte ptr 1
		mov cur_lrc_index, 0
		invoke ReadFile, hFile, addr lrc_buffer, sizeof lrc_buffer, addr actual_read_bytes, NULL
		mov times, 0
		invoke StrStrI,addr lrc_buffer, addr lrc_next_sentence
		mov esi, eax
		
		L2:
		movzx ebx, byte ptr [esi+1]
		.if ebx>=48
			.if ebx<=57
				;解析歌词进度，min:s.ms
				movzx eax, byte ptr [esi+1]
				sub eax, offs
				mov dscale, 10
				mul dscale
				
				movzx ebx, byte ptr [esi+2]
				sub ebx, offs
				add eax, ebx
				mov dscale, 60
				mul dscale
				
				push eax
				
				movzx eax, byte ptr [esi+4]
				sub eax, offs
				mov dscale, 10
				mul dscale
				
				movzx ebx, byte ptr [esi+5]
				sub ebx, offs
				add eax, ebx
				
				pop ebx	;取出分钟转换成的秒数
				
				add eax, ebx	;eax中存了总秒数
				
				mov dscale, 100
				mul dscale
				
				push eax
				
				movzx eax, byte ptr [esi+7]
				sub eax, offs
				mov dscale, 10
				mul dscale
				
				movzx ebx, byte ptr [esi+8]
				sub ebx,offs
				add eax, ebx
				
				pop ebx
				add eax, ebx
				
				mov dscale, 10
				mul dscale	
				
				mov current_time, eax
				mov eax, times
				mov ebx, TYPE dword
				mul ebx
				mov ebx, current_time
				mov [lrc_time + eax], ebx
				mov [lrc_addr + eax], esi
				
				invoke StrStrI,addr [esi+1], addr lrc_next_sentence
				.if eax != 0
					mov esi, eax	;esi指向下一个[的地址
					inc times
					jmp L2
				.else
					mov eax, times
					mov lyric_line_total, eax
					jmp L2_END
				.endif
			.else
				invoke StrStrI,addr [esi+1], addr lrc_next_sentence
				mov esi, eax
				cmp eax, 0
				jne L2
				jmp L2_END
			.endif
		.else
			invoke StrStrI,addr [esi+1], addr lrc_next_sentence
			mov esi, eax
			cmp eax, 0
			jne L2
			jmp L2_END
		.endif
	.endif
	L2_END:
	INVOKE CloseHandle, hFile
	
	Ret
read_lrc_file endp

;##################################################
; 实时显示歌词
;##################################################
show_lrc proc hWin:DWORD
	local present_line:DWORD
	local play_progress:DWORD
	.if play_state == PLAY_MUSIC		;tied with playing mode
		.if has_lyric == 1
			invoke mciSendString, addr cmd_getPos, addr current_pos, 32, NULL		;fetch current time pos to %eax
			invoke StrToInt, addr current_pos		;int->str in %eax
			mov play_progress, eax					;for checking which line the progress locate
			mov present_line, 0
			mov edx, present_line
			.while edx <= lyric_line_total
				mov eax, present_line
				mov ebx, TYPE dword
				mul ebx						;eax stores how much the present_line differs from lrc_array
				mov ebx, lrc_time[eax]	;lyric position
				;Middle line
				.if ebx > play_progress				;checking which line the progress locate(first to ">", later we'll Ret)
						
					mov edi, lrc_addr[eax];starting address
					mov ebx, present_line
					.if ebx == 0			;starting part of the song
						invoke SendDlgItemMessage, hWin, IDC_lyrics_current, WM_SETTEXT, 0, addr lrc_prepare
					.else
						mov eax, present_line
						mov ebx, TYPE dword
						mul ebx				;eax stores how much the present_line differs from lrc_array
						sub eax, TYPE dword
						mov esi, lrc_addr[eax];former line address
						mov edx, edi			;line address
						sub edx, esi			;Bytes that we should print
						sub edx, 10				;[3,12.1]should not be printed
						invoke lstrcpyn, addr long_str, addr [esi+10], edx
						invoke SendDlgItemMessage, hWin, IDC_lyrics_current, WM_SETTEXT, 0, addr long_str
					.endif

					;1st line
					dec present_line
					dec present_line
					mov edx, present_line
					mov eax, present_line
					mov ebx, TYPE dword
					mul ebx				;eax stores how much the present_line differs from lrc_array
					mov edi, lrc_addr[eax]
					mov ebx, lrc_time[eax]
					.if ebx <= 0
						;invoke lstrcpy, addr long_str, addr [edi+10]
						invoke SendDlgItemMessage, hWin, IDC_lyrics_prev2, WM_SETTEXT, 0, addr lrc_prepare
					.else
						mov eax, present_line
						mov ebx, TYPE dword
						mul ebx					;eax stores how much the present_line differs from lrc_array
						sub eax, TYPE dword
						mov esi, lrc_addr[eax];former line address
						mov edx, edi			;line address
						sub edx, esi			;Bytes that we should print
						sub edx, 10				;[3,12.1]should not be printed
						invoke lstrcpyn, addr long_str, addr [esi+10], edx
						invoke SendDlgItemMessage, hWin, IDC_lyrics_prev2, WM_SETTEXT, 0, addr long_str
					.endif
					inc present_line
					inc present_line

					;第二行
					dec present_line
					mov edx, present_line
					mov eax, present_line
					mov ebx, TYPE dword
					mul ebx					;eax stores how much the present_line differs from lrc_array
					mov edi, lrc_addr[eax]
					mov ebx, lrc_time[eax]
					.if ebx <= 0
						invoke SendDlgItemMessage, hWin, IDC_lyrics_prev1, WM_SETTEXT, 0, addr lrc_prepare
					.else
						mov eax, present_line
						mov ebx, TYPE dword
						mul ebx					;eax stores how much the present_line differs from lrc_array
						sub eax, TYPE dword
						mov esi, lrc_addr[eax];former line address
						mov edx, edi			;line address
						sub edx, esi			;Bytes that we should print
						sub edx, 10				;[3,12.1]should not be printed
						invoke lstrcpyn, addr long_str, addr [esi+10], edx
						invoke SendDlgItemMessage, hWin, IDC_lyrics_prev1, WM_SETTEXT, 0, addr long_str
					.endif
					inc present_line
						
					;第四行
					inc present_line
					mov edx, present_line
					mov eax, present_line
					mov ebx, TYPE dword
					mul ebx				;eax stores how much the present_line differs from lrc_array
					mov edi, lrc_addr[eax]
					mov ebx, lrc_time[eax]
						
					mov eax, present_line
					mov ebx, TYPE dword
					mul ebx						;eax stores how much the present_line differs from lrc_array
					sub eax, TYPE dword
					mov esi, lrc_addr[eax];former line address
					mov edx, edi			;line address
					sub edx, esi			;Bytes that we should print
					sub edx, 10				;[3,12.1]should not be printed
					invoke lstrcpyn, addr long_str, addr [esi+10], edx
					invoke SendDlgItemMessage, hWin, IDC_lyrics_next1, WM_SETTEXT, 0, addr long_str
					dec present_line
						
					;第五行
					inc present_line
					inc present_line
					mov edx, present_line
					mov eax, present_line
					mov ebx, TYPE dword
					mul ebx				;eax stores how much the present_line differs from lrc_array
					mov edi, lrc_addr[eax]
					mov ebx, lrc_time[eax]
						
					mov eax, present_line
					mov ebx, TYPE dword
					mul ebx				;eax stores how much the present_line differs from lrc_array
					sub eax, TYPE dword
					mov esi, lrc_addr[eax];former line address
					mov edx, edi			;line address
					sub edx, esi			;Bytes that we should print
					sub edx, 10				;[3,12.1]should not be printed
					invoke lstrcpyn, addr long_str, addr [esi+10], edx
					invoke SendDlgItemMessage, hWin, IDC_lyrics_next2, WM_SETTEXT, 0, addr long_str
					dec present_line
					dec present_line
					jmp dL_LEND
				.endif
				inc present_line
				mov edx, present_line
			.endw
		.endif
	.endif
	dL_LEND:
	Ret
show_lrc endp


;##################################################
; 打开歌曲
;##################################################
open_song proc hWin:DWORD, index:DWORD
	invoke read_lrc_file, hWin, index	;get the lyric functionally
	mov eax, index
	mov ebx, TYPE song_menu
	mul ebx						;eax stores how much the present_line differs from lrc_array
	invoke wsprintf, ADDR mci_cmd, ADDR cmd_open, ADDR song_menu[eax].music_path
	invoke mciSendString, ADDR mci_cmd, NULL, 0, NULL
	Ret
open_song endp


;##################################################
; 当点击播放按钮时
;##################################################
handle_play_btn proc hWin:DWORD
	.if play_state == STOP_MUSIC	;若当前为停止状态
		mov play_state, PLAY_MUSIC	;转为播放状态
		invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_SETCURSEL, current_index, 0
		invoke open_song,hWin, current_index	;打开选中音乐
		invoke mciSendString, ADDR cmd_play, NULL, 0, NULL	;播放音乐
		invoke alter_volume,hWin	;设置音量

		;修改图标
		mov eax, IMG_PAUSE
		invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
		invoke SendDlgItemMessage,hWin,IDC_paly_btn, BM_SETIMAGE, IMAGE_ICON, eax

		invoke mciSendString, addr cmd_getLen, addr current_len, 32, NULL	;获取当前音乐长度
		invoke StrToInt, addr current_len
		invoke SendDlgItemMessage, hWin, IDC_time_slider, TBM_SETRANGEMAX, 0, eax	;修改进度条长度
		
		;设置音乐时长格式
		invoke StrToInt, addr current_len
		mov edx, 0
		div scale_second
	
		mov edx, 0
		div scale_minute
		mov current_len_minute, eax
		mov current_len_second, edx

	.elseif play_state == PLAY_MUSIC	;当前为播放状态
		mov play_state, PAUSE_MUSIC		;转为暂停状态
		invoke mciSendString, ADDR cmd_pause, NULL, 0, NULL	;暂停歌曲
		
		;修改图标
		mov eax, IMG_START
		invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
		invoke SendDlgItemMessage,hWin,IDC_paly_btn, BM_SETIMAGE, IMAGE_ICON, eax

	.elseif play_state == PAUSE_MUSIC	;当前为暂停状态
		mov play_state, PLAY_MUSIC		;转为播放状态
		invoke mciSendString, ADDR cmd_resume, NULL, 0, NULL ;恢复播放

		;修改图标
		mov eax, IMG_PAUSE
		invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
		invoke SendDlgItemMessage,hWin,IDC_paly_btn, BM_SETIMAGE, IMAGE_ICON, eax
	.endif
	Ret
handle_play_btn endp

;##################################################
; 改变播放歌曲
;##################################################
alter_song proc hWin:DWORD, newSongIndex: DWORD
	.if play_state != STOP_MUSIC
		invoke mciSendString, ADDR cmd_close, NULL, 0, NULL
	.endif

	mov eax, newSongIndex
	mov current_index, eax  ;更新当前index
	invoke open_song,hWin, current_index	;打开新的歌曲
	.if play_state == PLAY_MUSIC
		invoke mciSendString, ADDR cmd_play, NULL, 0, NULL;播放歌曲
	.endif
	invoke alter_volume,hWin	;设置音量
	
	;设置进度条
	invoke mciSendString, addr cmd_getLen, addr current_len, 32, NULL
	invoke StrToInt, addr current_len
	invoke SendDlgItemMessage, hWin, IDC_time_slider, TBM_SETRANGEMAX, 0, eax
	
	;设置歌曲时长格式
	invoke StrToInt, addr current_len
	mov edx, 0
	div scale_second
	
	mov edx, 0
	div scale_minute
	mov current_len_minute, eax
	mov current_len_second, edx
	Ret
alter_song endp

;##################################################
; 播放列表添加歌曲
;##################################################
handle_add_btn proc uses eax ebx esi edi hWin:DWORD
	LOCAL len: DWORD	
	LOCAL cur_size: DWORD
	LOCAL cur_offset: DWORD
	LOCAL origin_offset: DWORD

	mov al,0
	mov edi, OFFSET open_file_dlg
	mov ecx, SIZEOF open_file_dlg
	cld
	rep stosb
	mov open_file_dlg.lStructSize, SIZEOF open_file_dlg
	mov eax, hWin
	mov open_file_dlg.hwndOwner, eax
	mov eax, OFN_ALLOWMULTISELECT
	or eax, OFN_EXPLORER
	mov open_file_dlg.Flags, eax
	mov open_file_dlg.nMaxFile, dlg_nmax_file
	mov open_file_dlg.lpstrTitle, OFFSET dlg_title
	mov open_file_dlg.lpstrInitialDir, OFFSET dlg_init_dir
	mov open_file_dlg.lpstrFile, OFFSET dlg_open_file_names
	invoke GetOpenFileName, ADDR open_file_dlg
	.IF eax == 1
		invoke lstrcpyn, ADDR dlg_path, ADDR dlg_open_file_names, open_file_dlg.nFileOffset
		invoke lstrlen, ADDR dlg_path
		mov len, eax
		mov ebx, eax
		mov al, dlg_path[ebx]
		.IF al != sep
			mov al, sep
			mov dlg_path[ebx], al
			mov dlg_path[ebx + 1], 0
		.ENDIF
		mov ebx, song_menu_size
		mov cur_size, ebx
		mov edi, OFFSET song_menu
		mov eax, SIZEOF Song
		mul ebx
		add edi, eax
		mov cur_offset, edi
		mov origin_offset, edi
		mov esi, OFFSET dlg_open_file_names
		mov eax, 0
		mov ax, open_file_dlg.nFileOffset
		add esi, eax
		mov al, [esi]
		.WHILE al != 0
			mov dlg_file_name, 0
			invoke lstrcat, ADDR dlg_file_name, ADDR dlg_path
			invoke lstrcat, ADDR dlg_file_name, esi
			mov edi, cur_offset
			add cur_offset, SIZEOF Song
			invoke lstrcpy, edi, esi
			add edi, 100
			invoke lstrcpy, edi, ADDR dlg_file_name
			invoke lstrlen, esi
			inc eax
			add esi, eax
			add song_menu_size, 1
			mov al, [esi]
		.ENDW
		mov esi, origin_offset
		mov ecx, song_menu_size
		sub ecx, cur_size
		.IF ecx > 0
			L1:
				push ecx
				invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_ADDSTRING, 0, ADDR (Song PTR [esi]).music_name
				add esi, TYPE song_menu
				pop ecx
			loop L1
		.ENDIF
	.ENDIF
	ret
handle_add_btn endp


;##################################################
; 删除歌曲列表中选中的曲子
;##################################################
handle_dele_btn proc hWin: DWORD
	invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_GETCURSEL, 0, 0	;获取被选中的下标
	.if eax == -1
		invoke MessageBox, hWin, ADDR dlg_warning, ADDR dlg_warning_title, MB_OK
	.else
		push eax
		invoke SendDlgItemMessage, hWin, IDC_song_menu, LB_DELETESTRING, eax, 0
		pop eax
		mov ebx, eax
		add ebx, 1
		mov edi, OFFSET song_menu
		mov edx, SIZEOF Song
		mul edx
		add edi, eax
		mov esi, edi
		add esi, SIZEOF Song
		.while ebx < song_menu_size
			mov ecx, SIZEOF Song
			cld
			rep movsb
			add ebx, 1
		.endw
		sub song_menu_size, 1
	.ENDIF
	ret
handle_dele_btn endp

;##################################################
; 改变音量
;##################################################
alter_volume proc hWin:	DWORD
	invoke SendDlgItemMessage,hWin,IDC_vol_slider,TBM_GETPOS,0,0	;获取当前Slider位置
	.if have_sound == 1
		invoke wsprintf, addr mci_cmd, addr cmd_setVol, eax
	.else
		invoke wsprintf, addr mci_cmd, addr cmd_setVol, 0
	.endif
	invoke mciSendString, addr mci_cmd, NULL, 0, NULL
	Ret
alter_volume endp


;##################################################
; 切换是否为静音的状态
;##################################################
handle_silence_btn proc hWin: DWORD
	.if have_sound == 1
		mov have_sound, 0
		mov eax, IMG_CLOSE_SOUND
	.else
		mov have_sound,1
		mov eax, IMG_OPEN_SOUND
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_silence_btn, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	invoke alter_volume,hWin
	Ret
handle_silence_btn endp

;##################################################
; 改变音量显示的数值
;##################################################
show_volume proc hWin: DWORD
	local tmp: DWORD
	invoke SendDlgItemMessage,hWin,IDC_vol_slider,TBM_GETPOS,0,0;获取当前Slider游标位置
	;设置文字显示音量
	mov tmp, 10
	mov edx, 0
	div tmp
	invoke wsprintf, addr mci_cmd, addr int_fmt, eax
	invoke SendDlgItemMessage, hWin, IDC_vol_txt, WM_SETTEXT, 0, addr mci_cmd
	Ret
show_volume endp

;##################################################
; 根据播放进度刷新进度条和播放时间
;##################################################
handle_time_slider proc hWin: DWORD
	local cur_pos: DWORD
	.if play_state == PLAY_MUSIC	;播放状态
		invoke mciSendString, addr cmd_getPos, addr current_pos, 32, NULL	;获取播放位置
		invoke StrToInt, addr current_pos
		mov cur_pos, eax
		.if dragging == 0	;放开拖拽进度条
			invoke SendDlgItemMessage, hWin, IDC_time_slider, TBM_SETPOS, 1, cur_pos
		.endif

		;刷新时间显示
		mov eax, cur_pos
		mov edx, 0
		div scale_second
	
		mov edx, 0
		div scale_minute
		mov current_pos_minute, eax
		mov current_pos_second, edx
		invoke wsprintf, addr mci_cmd, addr time_fmt, current_pos_minute, current_pos_second, current_len_minute, current_len_second
		invoke SendDlgItemMessage, hWin, IDC_time_txt, WM_SETTEXT, 0, addr mci_cmd;修改文字 

	.endif
	Ret
handle_time_slider endp


;##################################################
;修改播放时间
;##################################################
alter_time proc hWin: DWORD
	invoke SendDlgItemMessage,hWin,IDC_time_slider,TBM_GETPOS,0,0	;获取当前Slider位置
	invoke wsprintf, addr mci_cmd, addr cmd_setPos, eax
	invoke mciSendString, addr mci_cmd, NULL, 0, NULL
	.if play_state == PLAY_MUSIC
		invoke mciSendString, addr cmd_play, NULL, 0, NULL
	.elseif play_state == PAUSE_MUSIC
		invoke mciSendString, addr cmd_play, NULL, 0, NULL
		mov play_state, PLAY_MUSIC
		mov eax, IMG_PAUSE
		invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
		invoke SendDlgItemMessage,hWin,IDC_paly_btn, BM_SETIMAGE, IMAGE_ICON, eax
	.endif
	Ret
alter_time endp


;##################################################
; 切换循环状态
;##################################################
handle_recycle_btn proc hWin: DWORD
	.if repeat_mode == SINGLE_REPEAT
		mov repeat_mode, LIST_REPEAT
		mov eax, IMG_RECYCLE
	.elseif repeat_mode == LIST_REPEAT
		mov repeat_mode,RANDOM_REPEAT
		mov eax, IMG_RANDOM
	.elseif repeat_mode == RANDOM_REPEAT
		mov repeat_mode,SINGLE_REPEAT
		mov eax, IMG_SINGLE
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_recycle_btn, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	Ret
handle_recycle_btn endp


;##################################################
; 播放结束后根据循环模式进行下一首歌的切换
;##################################################
switch_next_song proc hWin: DWORD
	local temp: DWORD
	invoke StrToInt, addr current_len
	mov temp, eax
	invoke StrToInt, addr current_pos
	.if eax >= temp	;结束播放
		.if repeat_mode == SINGLE_REPEAT
			invoke mciSendString, addr cmd_setStart, NULL, 0, NULL
			invoke mciSendString, addr cmd_play, NULL, 0, NULL
		.elseif repeat_mode == LIST_REPEAT
			invoke SendMessage, hWin, WM_COMMAND, IDC_next_btn, 0;
		.elseif repeat_mode == RANDOM_REPEAT
			invoke SendMessage, hWin, WM_COMMAND, IDC_next_btn, 0
		.endif
	.endif
	Ret
switch_next_song endp
end start
