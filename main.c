//Bohdan Brzobohat�
#include "stm8s.h"
#include "milis.h"
#include "stm8_hd44780.h"
#include "stdio.h"
#include "swi2c.h"
#include "stm8s.h"

#define PULSE_LEN 2 // d�lka spou�t�c�ho (trigger) pulzu pro ultrazvuk
#define MEASURMENT_PERIOD 100 // perioda m��en� ultrazvukem (m�la by b�t v�c jak (maxim�ln�_dosah*2)/rychlost_zvuku)
void process_measurment(void);
void init_tim1(void);
uint16_t capture; // tady bude aktu�ln� v�sledek m��en� (�asu), v mikrosekund�ch us
uint8_t capture_flag=0; // tady budeme indikovat �e v capture je �erstv� v�sledek
char text[16];
uint32_t time2=0;
uint32_t vzdalenost=0;
uint16_t vzd1=0;
#define DETEKCE_VZDALENOSTI 10

#define RTC_ADRESS 0b11010000   //Makro pro adresu RTC obvodu
void init_tim3(void);  //funkce, kter� nastav� timer 3 
void read_RTC(void);   //funkce, kter� ka�d�ch 100 ms vy��t� informace z RTC
volatile uint8_t error;
volatile uint8_t RTC_precteno[7];    // pole o d�lce 7 byt�, kam ukl�d�m data o �ase
volatile uint8_t zapis[7];				   //pole o d�lce 7 byt�, ze kter�ho zapisuju data do RTC
uint16_t sec,des_sec,min,des_min,hod,des_hod,zbytek_hod;
volatile bool read_flag=0;
uint8_t stav=0;

uint8_t i=0;


void main(void){
CLK_HSIPrescalerConfig(CLK_PRESCALER_HSIDIV1); // 16MHz z intern�ho RC oscil�toru
init_milis(); // milis kv�li delay_ms()
init_tim1(); // nastavit a spustit timer
lcd_init();
lcd_clear();
GPIO_Init(GPIOG, GPIO_PIN_0, GPIO_MODE_OUT_PP_LOW_SLOW); // v�stup - "trigger pulz pro ultrazvuk"

enableInterrupts();  //glob�ln� povol� p�eru�en�
swi2c_init();
init_tim3(); // nastavit a spustit timer
zapis[0] = 0b00000000;
zapis[1] = 0b00001000;
zapis[2] = 0b00010101;//prvn� p�lka des�tky, druh� jednotky
//swi2c_write_buf(RTC_ADRESS,0x00,zapis,3);


  while (1){
		
		read_RTC();
		process_measurment(); // obsluhuje neblokuj�c�m zp�sobem m��en� ultrazvukem
		
		
		if (read_flag){//zobrazen� aktu�ln�ho �asu
			read_flag=0;
			sprintf(text,"time: %u%u:%u%u:%u%u",des_hod,hod,des_min,min,des_sec,sec);//
			lcd_gotoxy(0,1);
			lcd_puts(text);
		}
		
		if (milis()-time2>332){//zobrazen� aktu�ln� vzd�lenosti
			time2=milis();
			vzdalenost=capture/2;
			vzdalenost=vzdalenost*343;
			vzd1=vzdalenost/10000;
			sprintf(text,"distance: %3ucm",vzd1);
			lcd_gotoxy(0,0);
			lcd_puts(text);
		}
		

  } 
}




void read_RTC(void){
static uint16_t last_time=0;      // ka�d�ch 100ms p�e�te obsah RTC
  if(milis() - last_time >= 100){
    last_time = milis(); 
    error=swi2c_read_buf(RTC_ADRESS,0x00,RTC_precteno,7);
		
		sec = (RTC_precteno[0] & 0b00001111);              //sekundy
		des_sec = ((RTC_precteno[0] >> 4) & 0b00001111);		 //des�tky sekund
		min = (RTC_precteno[1] & 0b00001111);		                //minuty
		des_min = ((RTC_precteno[1] >> 4) & 0b00001111);   //des�tky minut
		hod = (RTC_precteno[2] & 0b00001111); 						//hodiny
		des_hod = ((RTC_precteno[2] >> 4) & 0b00000011);  //des�tky hodin
		zbytek_hod = ((RTC_precteno[2] >> 4) & 0b00001111);   //zbytek dat hodin 
	}
}



void init_tim3(void){
TIM3_TimeBaseInit(TIM3_PRESCALER_16,1999); // clock 1MHz, strop 5000 => perioda p�ete�en� 5 ms
TIM3_ITConfig(TIM3_IT_UPDATE, ENABLE); // povol�me p�eru�en� od update ud�losti (p�ete�en�) timeru 3
TIM3_Cmd(ENABLE); // spust�me timer 3
}


INTERRUPT_HANDLER(TIM3_UPD_OVF_BRK_IRQHandler, 15){    //funkce pro obsluhu displej�
  TIM3_ClearITPendingBit(TIM3_IT_UPDATE);
	read_flag=1;
}


void process_measurment(void){
	static uint8_t stage=0; // stavov� automat
	static uint16_t time=0; // pro �asov�n� pomoc� milis
	switch(stage){
	case 0:	// �ek�me ne� uplyne  MEASURMENT_PERIOD abychom odstartovali m��en�
		if(milis()-time > MEASURMENT_PERIOD){
			time = milis(); 
			GPIO_WriteHigh(GPIOG,GPIO_PIN_0); // zah�j�me trigger pulz
			stage = 1; // a bdueme �ekat a� uplyne �as trigger pulzu
		}
		break;
	case 1: // �ek�me ne� uplyne PULSE_LEN (generuje trigger pulse)
		if(milis()-time > PULSE_LEN){
			GPIO_WriteLow(GPIOG,GPIO_PIN_0); // ukon��me trigger pulz
			stage = 2; // a p�ejdeme do f�ze kdy o�ek�v�me echo
		}
		break;
	case 2: // �ek�me jestli dostaneme odezvu (�ek�me na echo)
		if(TIM1_GetFlagStatus(TIM1_FLAG_CC2) != RESET){ // hl�d�me zda timer hl�s� zm��en� pulzu
			capture = TIM1_GetCapture2(); // ulo��me v�sledek m��en�
			capture_flag=1; // d�me v�d�t zbytku programu �e m�me nov� platn� v�sledek
			stage = 0; // a za�neme znovu od za��tku
		}else if(milis()-time > MEASURMENT_PERIOD){ // pokud timer nezachytil pulz po dlouhou dobu, tak echo nep�ijde
			stage = 0; // a za�neme znovu od za��tku
		}		
		break;
	default: // pokud se cokoli pokaz�
	stage = 0; // za�neme znovu od za��tku
	}	
}

void init_tim1(void){
GPIO_Init(GPIOC, GPIO_PIN_1, GPIO_MODE_IN_FL_NO_IT); // PC1 (TIM1_CH1) jako vstup
TIM1_TimeBaseInit(15,TIM1_COUNTERMODE_UP,0xffff,0); // timer nech�me voln� b�et (do maxim�ln�ho stropu) s �asovou z�kladnou 1MHz (1us)
// Konfigurujeme parametry capture kan�lu 1 - komplikovan�, nelze popsat v kr�tk�m koment��i
TIM1_ICInit(TIM1_CHANNEL_1,TIM1_ICPOLARITY_RISING,TIM1_ICSELECTION_DIRECTTI,TIM1_ICPSC_DIV1,0);
// Konfigurujeme parametry capture kan�lu 2 - komplikovan�, nelze popsat v kr�tk�m koment��i
TIM1_ICInit(TIM1_CHANNEL_2,TIM1_ICPOLARITY_FALLING,TIM1_ICSELECTION_INDIRECTTI,TIM1_ICPSC_DIV1,0);
TIM1_SelectInputTrigger(TIM1_TS_TI1FP1); // Zdroj sign�lu pro Clock/Trigger controller 
TIM1_SelectSlaveMode(TIM1_SLAVEMODE_RESET); // Clock/Trigger m� po p��chodu sign�lu prov�st RESET timeru
TIM1_ClearFlag(TIM1_FLAG_CC2); // pro jistotu vy�ist�me vlajku signalizuj�c� z�chyt a zm��en� echo pulzu
TIM1_Cmd(ENABLE); // spust�me timer a� b�� na pozad�
}


#ifdef USE_FULL_ASSERT
void assert_failed(u8* file, u32 line)
{ 

  while (1){}
}
#endif
