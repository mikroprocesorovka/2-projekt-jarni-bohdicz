   1                     ; C Compiler for STM8 (COSMIC Software)
   2                     ; Parser V4.12.1 - 30 Jun 2020
   3                     ; Generator (Limited) V4.4.12 - 02 Jul 2020
  15                     	bsct
  16  0000               _capture_flag:
  17  0000 00            	dc.b	0
  18  0001               _time2:
  19  0001 00000000      	dc.l	0
  20  0005               _vzdalenost:
  21  0005 00000000      	dc.l	0
  22  0009               _vzd1:
  23  0009 0000          	dc.w	0
  24  000b               _read_flag:
  25  000b 00            	dc.b	0
  26  000c               _stav:
  27  000c 00            	dc.b	0
  28  000d               _i:
  29  000d 00            	dc.b	0
  87                     .const:	section	.text
  88  0000               L6:
  89  0000 0000014d      	dc.l	333
  90  0004               L01:
  91  0004 00002710      	dc.l	10000
  92                     ; 33 void main(void){
  93                     	scross	off
  94                     	switch	.text
  95  0000               _main:
  99                     ; 34 CLK_HSIPrescalerConfig(CLK_PRESCALER_HSIDIV1); // 16MHz z internÌho RC oscil·toru
 101  0000 4f            	clr	a
 102  0001 cd0000        	call	_CLK_HSIPrescalerConfig
 104                     ; 35 init_milis(); // milis kv˘li delay_ms()
 106  0004 cd0000        	call	_init_milis
 108                     ; 36 init_tim1(); // nastavit a spustit timer
 110  0007 cd01de        	call	_init_tim1
 112                     ; 37 lcd_init();
 114  000a cd0000        	call	_lcd_init
 116                     ; 38 lcd_clear();
 118  000d a601          	ld	a,#1
 119  000f cd0000        	call	_lcd_command
 121                     ; 39 GPIO_Init(GPIOG, GPIO_PIN_0, GPIO_MODE_OUT_PP_LOW_SLOW); // v˝stup - "trigger pulz pro ultrazvuk"
 123  0012 4bc0          	push	#192
 124  0014 4b01          	push	#1
 125  0016 ae501e        	ldw	x,#20510
 126  0019 cd0000        	call	_GPIO_Init
 128  001c 85            	popw	x
 129                     ; 41 enableInterrupts();  //glob·lnÏ povolÌ p¯eruöenÌ
 132  001d 9a            rim
 134                     ; 42 swi2c_init();
 137  001e cd0000        	call	_swi2c_init
 139                     ; 43 init_tim3(); // nastavit a spustit timer
 141  0021 cd0131        	call	_init_tim3
 143                     ; 44 zapis[0] = 0b00000000;
 145  0024 3f0e          	clr	_zapis
 146                     ; 45 zapis[1] = 0b00001000;
 148  0026 3508000f      	mov	_zapis+1,#8
 149                     ; 46 zapis[2] = 0b00010101;//prvnÌ p˘lka desÌtky, druh· jednotky
 151  002a 35150010      	mov	_zapis+2,#21
 152  002e               L52:
 153                     ; 52 		read_RTC();
 155  002e cd00cd        	call	_read_RTC
 157                     ; 53 		process_measurment(); // obsluhuje neblokujÌcÌm zp˘sobem mÏ¯enÌ ultrazvukem
 159  0031 cd016f        	call	_process_measurment
 161                     ; 56 		if (read_flag){//zobrazenÌ aktu·lnÌho Ëasu
 163  0034 3d0b          	tnz	_read_flag
 164  0036 272c          	jreq	L13
 165                     ; 57 			read_flag=0;
 167  0038 3f0b          	clr	_read_flag
 168                     ; 58 			sprintf(text,"time: %u%u:%u%u:%u%u",des_hod,hod,des_min,min,des_sec,sec);//
 170  003a be0c          	ldw	x,_sec
 171  003c 89            	pushw	x
 172  003d be0a          	ldw	x,_des_sec
 173  003f 89            	pushw	x
 174  0040 be08          	ldw	x,_min
 175  0042 89            	pushw	x
 176  0043 be06          	ldw	x,_des_min
 177  0045 89            	pushw	x
 178  0046 be04          	ldw	x,_hod
 179  0048 89            	pushw	x
 180  0049 be02          	ldw	x,_des_hod
 181  004b 89            	pushw	x
 182  004c ae0018        	ldw	x,#L33
 183  004f 89            	pushw	x
 184  0050 ae001d        	ldw	x,#_text
 185  0053 cd0000        	call	_sprintf
 187  0056 5b0e          	addw	sp,#14
 188                     ; 59 			lcd_gotoxy(0,1);
 190  0058 ae0001        	ldw	x,#1
 191  005b cd0000        	call	_lcd_gotoxy
 193                     ; 60 			lcd_puts(text);
 195  005e ae001d        	ldw	x,#_text
 196  0061 cd0000        	call	_lcd_puts
 198  0064               L13:
 199                     ; 63 		if (milis()-time2>332){//zobrazenÌ aktu·lnÌ vzd·lenosti
 201  0064 cd0000        	call	_milis
 203  0067 cd0000        	call	c_uitolx
 205  006a ae0001        	ldw	x,#_time2
 206  006d cd0000        	call	c_lsub
 208  0070 ae0000        	ldw	x,#L6
 209  0073 cd0000        	call	c_lcmp
 211  0076 25b6          	jrult	L52
 212                     ; 64 			time2=milis();
 214  0078 cd0000        	call	_milis
 216  007b cd0000        	call	c_uitolx
 218  007e ae0001        	ldw	x,#_time2
 219  0081 cd0000        	call	c_rtol
 221                     ; 65 			vzdalenost=capture/2;
 223  0084 be2d          	ldw	x,_capture
 224  0086 54            	srlw	x
 225  0087 cd0000        	call	c_uitolx
 227  008a ae0005        	ldw	x,#_vzdalenost
 228  008d cd0000        	call	c_rtol
 230                     ; 66 			vzdalenost=vzdalenost*343;
 232  0090 ae0157        	ldw	x,#343
 233  0093 bf02          	ldw	c_lreg+2,x
 234  0095 ae0000        	ldw	x,#0
 235  0098 bf00          	ldw	c_lreg,x
 236  009a ae0005        	ldw	x,#_vzdalenost
 237  009d cd0000        	call	c_lgmul
 239                     ; 67 			vzd1=vzdalenost/10000;
 241  00a0 ae0005        	ldw	x,#_vzdalenost
 242  00a3 cd0000        	call	c_ltor
 244  00a6 ae0004        	ldw	x,#L01
 245  00a9 cd0000        	call	c_ludv
 247  00ac be02          	ldw	x,c_lreg+2
 248  00ae bf09          	ldw	_vzd1,x
 249                     ; 68 			sprintf(text,"distance: %3ucm",vzd1);
 251  00b0 be09          	ldw	x,_vzd1
 252  00b2 89            	pushw	x
 253  00b3 ae0008        	ldw	x,#L73
 254  00b6 89            	pushw	x
 255  00b7 ae001d        	ldw	x,#_text
 256  00ba cd0000        	call	_sprintf
 258  00bd 5b04          	addw	sp,#4
 259                     ; 69 			lcd_gotoxy(0,0);
 261  00bf 5f            	clrw	x
 262  00c0 cd0000        	call	_lcd_gotoxy
 264                     ; 70 			lcd_puts(text);
 266  00c3 ae001d        	ldw	x,#_text
 267  00c6 cd0000        	call	_lcd_puts
 269  00c9 ac2e002e      	jpf	L52
 272                     	bsct
 273  000e               L14_last_time:
 274  000e 0000          	dc.w	0
 317                     ; 80 void read_RTC(void){
 318                     	switch	.text
 319  00cd               _read_RTC:
 323                     ; 82   if(milis() - last_time >= 100){
 325  00cd cd0000        	call	_milis
 327  00d0 72b0000e      	subw	x,L14_last_time
 328  00d4 a30064        	cpw	x,#100
 329  00d7 2557          	jrult	L16
 330                     ; 83     last_time = milis(); 
 332  00d9 cd0000        	call	_milis
 334  00dc bf0e          	ldw	L14_last_time,x
 335                     ; 84     error=swi2c_read_buf(RTC_ADRESS,0x00,RTC_precteno,7);
 337  00de ae0007        	ldw	x,#7
 338  00e1 89            	pushw	x
 339  00e2 ae0015        	ldw	x,#_RTC_precteno
 340  00e5 89            	pushw	x
 341  00e6 aed000        	ldw	x,#53248
 342  00e9 cd0000        	call	_swi2c_read_buf
 344  00ec 5b04          	addw	sp,#4
 345  00ee b71c          	ld	_error,a
 346                     ; 86 		sec = (RTC_precteno[0] & 0b00001111);              //sekundy
 348  00f0 b615          	ld	a,_RTC_precteno
 349  00f2 a40f          	and	a,#15
 350  00f4 5f            	clrw	x
 351  00f5 97            	ld	xl,a
 352  00f6 bf0c          	ldw	_sec,x
 353                     ; 87 		des_sec = ((RTC_precteno[0] >> 4) & 0b00001111);		 //desÌtky sekund
 355  00f8 b615          	ld	a,_RTC_precteno
 356  00fa 4e            	swap	a
 357  00fb a40f          	and	a,#15
 358  00fd 5f            	clrw	x
 359  00fe 97            	ld	xl,a
 360  00ff bf0a          	ldw	_des_sec,x
 361                     ; 88 		min = (RTC_precteno[1] & 0b00001111);		                //minuty
 363  0101 b616          	ld	a,_RTC_precteno+1
 364  0103 a40f          	and	a,#15
 365  0105 5f            	clrw	x
 366  0106 97            	ld	xl,a
 367  0107 bf08          	ldw	_min,x
 368                     ; 89 		des_min = ((RTC_precteno[1] >> 4) & 0b00001111);   //desÌtky minut
 370  0109 b616          	ld	a,_RTC_precteno+1
 371  010b 4e            	swap	a
 372  010c a40f          	and	a,#15
 373  010e 5f            	clrw	x
 374  010f 97            	ld	xl,a
 375  0110 bf06          	ldw	_des_min,x
 376                     ; 90 		hod = (RTC_precteno[2] & 0b00001111); 						//hodiny
 378  0112 b617          	ld	a,_RTC_precteno+2
 379  0114 a40f          	and	a,#15
 380  0116 5f            	clrw	x
 381  0117 97            	ld	xl,a
 382  0118 bf04          	ldw	_hod,x
 383                     ; 91 		des_hod = ((RTC_precteno[2] >> 4) & 0b00000011);  //desÌtky hodin
 385  011a b617          	ld	a,_RTC_precteno+2
 386  011c 4e            	swap	a
 387  011d a40f          	and	a,#15
 388  011f 5f            	clrw	x
 389  0120 a403          	and	a,#3
 390  0122 5f            	clrw	x
 391  0123 5f            	clrw	x
 392  0124 97            	ld	xl,a
 393  0125 bf02          	ldw	_des_hod,x
 394                     ; 92 		zbytek_hod = ((RTC_precteno[2] >> 4) & 0b00001111);   //zbytek dat hodin 
 396  0127 b617          	ld	a,_RTC_precteno+2
 397  0129 4e            	swap	a
 398  012a a40f          	and	a,#15
 399  012c 5f            	clrw	x
 400  012d 97            	ld	xl,a
 401  012e bf00          	ldw	_zbytek_hod,x
 402  0130               L16:
 403                     ; 94 }
 406  0130 81            	ret
 432                     ; 98 void init_tim3(void){
 433                     	switch	.text
 434  0131               _init_tim3:
 438                     ; 99 TIM3_TimeBaseInit(TIM3_PRESCALER_16,1999); // clock 1MHz, strop 5000 => perioda p¯eteËenÌ 5 ms
 440  0131 ae07cf        	ldw	x,#1999
 441  0134 89            	pushw	x
 442  0135 a604          	ld	a,#4
 443  0137 cd0000        	call	_TIM3_TimeBaseInit
 445  013a 85            	popw	x
 446                     ; 100 TIM3_ITConfig(TIM3_IT_UPDATE, ENABLE); // povolÌme p¯eruöenÌ od update ud·losti (p¯eteËenÌ) timeru 3
 448  013b ae0101        	ldw	x,#257
 449  013e cd0000        	call	_TIM3_ITConfig
 451                     ; 101 TIM3_Cmd(ENABLE); // spustÌme timer 3
 453  0141 a601          	ld	a,#1
 454  0143 cd0000        	call	_TIM3_Cmd
 456                     ; 102 }
 459  0146 81            	ret
 485                     ; 105 INTERRUPT_HANDLER(TIM3_UPD_OVF_BRK_IRQHandler, 15){    //funkce pro obsluhu displej˘
 487                     	switch	.text
 488  0147               f_TIM3_UPD_OVF_BRK_IRQHandler:
 490  0147 8a            	push	cc
 491  0148 84            	pop	a
 492  0149 a4bf          	and	a,#191
 493  014b 88            	push	a
 494  014c 86            	pop	cc
 495  014d 3b0002        	push	c_x+2
 496  0150 be00          	ldw	x,c_x
 497  0152 89            	pushw	x
 498  0153 3b0002        	push	c_y+2
 499  0156 be00          	ldw	x,c_y
 500  0158 89            	pushw	x
 503                     ; 106   TIM3_ClearITPendingBit(TIM3_IT_UPDATE);
 505  0159 a601          	ld	a,#1
 506  015b cd0000        	call	_TIM3_ClearITPendingBit
 508                     ; 107 	read_flag=1;
 510  015e 3501000b      	mov	_read_flag,#1
 511                     ; 108 }
 514  0162 85            	popw	x
 515  0163 bf00          	ldw	c_y,x
 516  0165 320002        	pop	c_y+2
 517  0168 85            	popw	x
 518  0169 bf00          	ldw	c_x,x
 519  016b 320002        	pop	c_x+2
 520  016e 80            	iret
 522                     	bsct
 523  0010               L301_stage:
 524  0010 00            	dc.b	0
 525  0011               L501_time:
 526  0011 0000          	dc.w	0
 574                     ; 111 void process_measurment(void){
 576                     	switch	.text
 577  016f               _process_measurment:
 581                     ; 114 	switch(stage){
 583  016f b610          	ld	a,L301_stage
 585                     ; 137 	default: // pokud se cokoli pokazÌ
 585                     ; 138 	stage = 0; // zaËneme znovu od zaË·tku
 586  0171 4d            	tnz	a
 587  0172 270a          	jreq	L701
 588  0174 4a            	dec	a
 589  0175 2727          	jreq	L111
 590  0177 4a            	dec	a
 591  0178 273f          	jreq	L311
 592  017a               L511:
 595  017a 3f10          	clr	L301_stage
 596  017c 205f          	jra	L341
 597  017e               L701:
 598                     ; 115 	case 0:	// Ëek·me neû uplyne  MEASURMENT_PERIOD abychom odstartovali mÏ¯enÌ
 598                     ; 116 		if(milis()-time > MEASURMENT_PERIOD){
 600  017e cd0000        	call	_milis
 602  0181 72b00011      	subw	x,L501_time
 603  0185 a30065        	cpw	x,#101
 604  0188 2553          	jrult	L341
 605                     ; 117 			time = milis(); 
 607  018a cd0000        	call	_milis
 609  018d bf11          	ldw	L501_time,x
 610                     ; 118 			GPIO_WriteHigh(GPIOG,GPIO_PIN_0); // zah·jÌme trigger pulz
 612  018f 4b01          	push	#1
 613  0191 ae501e        	ldw	x,#20510
 614  0194 cd0000        	call	_GPIO_WriteHigh
 616  0197 84            	pop	a
 617                     ; 119 			stage = 1; // a bdueme Ëekat aû uplyne Ëas trigger pulzu
 619  0198 35010010      	mov	L301_stage,#1
 620  019c 203f          	jra	L341
 621  019e               L111:
 622                     ; 122 	case 1: // Ëek·me neû uplyne PULSE_LEN (generuje trigger pulse)
 622                     ; 123 		if(milis()-time > PULSE_LEN){
 624  019e cd0000        	call	_milis
 626  01a1 72b00011      	subw	x,L501_time
 627  01a5 a30003        	cpw	x,#3
 628  01a8 2533          	jrult	L341
 629                     ; 124 			GPIO_WriteLow(GPIOG,GPIO_PIN_0); // ukonËÌme trigger pulz
 631  01aa 4b01          	push	#1
 632  01ac ae501e        	ldw	x,#20510
 633  01af cd0000        	call	_GPIO_WriteLow
 635  01b2 84            	pop	a
 636                     ; 125 			stage = 2; // a p¯ejdeme do f·ze kdy oËek·v·me echo
 638  01b3 35020010      	mov	L301_stage,#2
 639  01b7 2024          	jra	L341
 640  01b9               L311:
 641                     ; 128 	case 2: // Ëek·me jestli dostaneme odezvu (Ëek·me na echo)
 641                     ; 129 		if(TIM1_GetFlagStatus(TIM1_FLAG_CC2) != RESET){ // hlÌd·me zda timer hl·sÌ zmÏ¯enÌ pulzu
 643  01b9 ae0004        	ldw	x,#4
 644  01bc cd0000        	call	_TIM1_GetFlagStatus
 646  01bf 4d            	tnz	a
 647  01c0 270d          	jreq	L151
 648                     ; 130 			capture = TIM1_GetCapture2(); // uloûÌme v˝sledek mÏ¯enÌ
 650  01c2 cd0000        	call	_TIM1_GetCapture2
 652  01c5 bf2d          	ldw	_capture,x
 653                     ; 131 			capture_flag=1; // d·me vÏdÏt zbytku programu ûe m·me nov˝ platn˝ v˝sledek
 655  01c7 35010000      	mov	_capture_flag,#1
 656                     ; 132 			stage = 0; // a zaËneme znovu od zaË·tku
 658  01cb 3f10          	clr	L301_stage
 660  01cd 200e          	jra	L341
 661  01cf               L151:
 662                     ; 133 		}else if(milis()-time > MEASURMENT_PERIOD){ // pokud timer nezachytil pulz po dlouhou dobu, tak echo nep¯ijde
 664  01cf cd0000        	call	_milis
 666  01d2 72b00011      	subw	x,L501_time
 667  01d6 a30065        	cpw	x,#101
 668  01d9 2502          	jrult	L341
 669                     ; 134 			stage = 0; // a zaËneme znovu od zaË·tku
 671  01db 3f10          	clr	L301_stage
 672  01dd               L341:
 673                     ; 140 }
 676  01dd 81            	ret
 706                     ; 142 void init_tim1(void){
 707                     	switch	.text
 708  01de               _init_tim1:
 712                     ; 143 GPIO_Init(GPIOC, GPIO_PIN_1, GPIO_MODE_IN_FL_NO_IT); // PC1 (TIM1_CH1) jako vstup
 714  01de 4b00          	push	#0
 715  01e0 4b02          	push	#2
 716  01e2 ae500a        	ldw	x,#20490
 717  01e5 cd0000        	call	_GPIO_Init
 719  01e8 85            	popw	x
 720                     ; 144 TIM1_TimeBaseInit(15,TIM1_COUNTERMODE_UP,0xffff,0); // timer nech·me volnÏ bÏûet (do maxim·lnÌho stropu) s Ëasovou z·kladnou 1MHz (1us)
 722  01e9 4b00          	push	#0
 723  01eb aeffff        	ldw	x,#65535
 724  01ee 89            	pushw	x
 725  01ef 4b00          	push	#0
 726  01f1 ae000f        	ldw	x,#15
 727  01f4 cd0000        	call	_TIM1_TimeBaseInit
 729  01f7 5b04          	addw	sp,#4
 730                     ; 146 TIM1_ICInit(TIM1_CHANNEL_1,TIM1_ICPOLARITY_RISING,TIM1_ICSELECTION_DIRECTTI,TIM1_ICPSC_DIV1,0);
 732  01f9 4b00          	push	#0
 733  01fb 4b00          	push	#0
 734  01fd 4b01          	push	#1
 735  01ff 5f            	clrw	x
 736  0200 cd0000        	call	_TIM1_ICInit
 738  0203 5b03          	addw	sp,#3
 739                     ; 148 TIM1_ICInit(TIM1_CHANNEL_2,TIM1_ICPOLARITY_FALLING,TIM1_ICSELECTION_INDIRECTTI,TIM1_ICPSC_DIV1,0);
 741  0205 4b00          	push	#0
 742  0207 4b00          	push	#0
 743  0209 4b02          	push	#2
 744  020b ae0101        	ldw	x,#257
 745  020e cd0000        	call	_TIM1_ICInit
 747  0211 5b03          	addw	sp,#3
 748                     ; 149 TIM1_SelectInputTrigger(TIM1_TS_TI1FP1); // Zdroj sign·lu pro Clock/Trigger controller 
 750  0213 a650          	ld	a,#80
 751  0215 cd0000        	call	_TIM1_SelectInputTrigger
 753                     ; 150 TIM1_SelectSlaveMode(TIM1_SLAVEMODE_RESET); // Clock/Trigger m· po p¯Ìchodu sign·lu provÈst RESET timeru
 755  0218 a604          	ld	a,#4
 756  021a cd0000        	call	_TIM1_SelectSlaveMode
 758                     ; 151 TIM1_ClearFlag(TIM1_FLAG_CC2); // pro jistotu vyËistÌme vlajku signalizujÌcÌ z·chyt a zmÏ¯enÌ echo pulzu
 760  021d ae0004        	ldw	x,#4
 761  0220 cd0000        	call	_TIM1_ClearFlag
 763                     ; 152 TIM1_Cmd(ENABLE); // spustÌme timer aù bÏûÌ na pozadÌ
 765  0223 a601          	ld	a,#1
 766  0225 cd0000        	call	_TIM1_Cmd
 768                     ; 153 }
 771  0228 81            	ret
 806                     ; 157 void assert_failed(u8* file, u32 line)
 806                     ; 158 { 
 807                     	switch	.text
 808  0229               _assert_failed:
 812  0229               L502:
 813  0229 20fe          	jra	L502
1023                     	xdef	f_TIM3_UPD_OVF_BRK_IRQHandler
1024                     	xdef	_main
1025                     	xdef	_i
1026                     	xdef	_stav
1027                     	xdef	_read_flag
1028                     	switch	.ubsct
1029  0000               _zbytek_hod:
1030  0000 0000          	ds.b	2
1031                     	xdef	_zbytek_hod
1032  0002               _des_hod:
1033  0002 0000          	ds.b	2
1034                     	xdef	_des_hod
1035  0004               _hod:
1036  0004 0000          	ds.b	2
1037                     	xdef	_hod
1038  0006               _des_min:
1039  0006 0000          	ds.b	2
1040                     	xdef	_des_min
1041  0008               _min:
1042  0008 0000          	ds.b	2
1043                     	xdef	_min
1044  000a               _des_sec:
1045  000a 0000          	ds.b	2
1046                     	xdef	_des_sec
1047  000c               _sec:
1048  000c 0000          	ds.b	2
1049                     	xdef	_sec
1050  000e               _zapis:
1051  000e 000000000000  	ds.b	7
1052                     	xdef	_zapis
1053  0015               _RTC_precteno:
1054  0015 000000000000  	ds.b	7
1055                     	xdef	_RTC_precteno
1056  001c               _error:
1057  001c 00            	ds.b	1
1058                     	xdef	_error
1059                     	xdef	_read_RTC
1060                     	xdef	_init_tim3
1061                     	xdef	_vzd1
1062                     	xdef	_vzdalenost
1063                     	xdef	_time2
1064  001d               _text:
1065  001d 000000000000  	ds.b	16
1066                     	xdef	_text
1067                     	xdef	_capture_flag
1068  002d               _capture:
1069  002d 0000          	ds.b	2
1070                     	xdef	_capture
1071                     	xdef	_init_tim1
1072                     	xdef	_process_measurment
1073                     	xref	_swi2c_read_buf
1074                     	xref	_swi2c_init
1075                     	xref	_sprintf
1076                     	xref	_lcd_puts
1077                     	xref	_lcd_gotoxy
1078                     	xref	_lcd_init
1079                     	xref	_lcd_command
1080                     	xref	_init_milis
1081                     	xref	_milis
1082                     	xdef	_assert_failed
1083                     	xref	_TIM3_ClearITPendingBit
1084                     	xref	_TIM3_ITConfig
1085                     	xref	_TIM3_Cmd
1086                     	xref	_TIM3_TimeBaseInit
1087                     	xref	_TIM1_ClearFlag
1088                     	xref	_TIM1_GetFlagStatus
1089                     	xref	_TIM1_GetCapture2
1090                     	xref	_TIM1_SelectSlaveMode
1091                     	xref	_TIM1_SelectInputTrigger
1092                     	xref	_TIM1_Cmd
1093                     	xref	_TIM1_ICInit
1094                     	xref	_TIM1_TimeBaseInit
1095                     	xref	_GPIO_WriteLow
1096                     	xref	_GPIO_WriteHigh
1097                     	xref	_GPIO_Init
1098                     	xref	_CLK_HSIPrescalerConfig
1099                     	switch	.const
1100  0008               L73:
1101  0008 64697374616e  	dc.b	"distance: %3ucm",0
1102  0018               L33:
1103  0018 74696d653a20  	dc.b	"time: %u%u:%u%u:%u"
1104  002a 257500        	dc.b	"%u",0
1105                     	xref.b	c_lreg
1106                     	xref.b	c_x
1107                     	xref.b	c_y
1127                     	xref	c_ludv
1128                     	xref	c_ltor
1129                     	xref	c_lgmul
1130                     	xref	c_rtol
1131                     	xref	c_lcmp
1132                     	xref	c_lsub
1133                     	xref	c_uitolx
1134                     	end
