//Bohdan Brzobohatı
#include "stm8s.h"
#include "milis.h"
#include "stm8_hd44780.h"
#include "stdio.h"
#include "swi2c.h"
#include "stm8s.h"

#define PULSE_LEN 2 // délka spouštìcího (trigger) pulzu pro ultrazvuk
#define MEASURMENT_PERIOD 100 // perioda mìøení ultrazvukem (mìla by bıt víc jak (maximální_dosah*2)/rychlost_zvuku)
void process_measurment(void);
void init_tim1(void);
uint16_t capture; // tady bude aktuální vısledek mìøení (èasu), v mikrosekundách us
uint8_t capture_flag=0; // tady budeme indikovat e v capture je èerstvı vısledek
char text[16];
uint32_t time2=0;
uint32_t vzdalenost=0;
uint16_t vzd1=0;
#define DETEKCE_VZDALENOSTI 10

#define RTC_ADRESS 0b11010000   //Makro pro adresu RTC obvodu
void init_tim3(void);  //funkce, která nastaví timer 3 
void read_RTC(void);   //funkce, která kadıch 100 ms vyèítá informace z RTC
volatile uint8_t error;
volatile uint8_t RTC_precteno[7];    // pole o délce 7 bytù, kam ukládám data o èase
volatile uint8_t zapis[7];				   //pole o délce 7 bytù, ze kterého zapisuju data do RTC
uint16_t sec,des_sec,min,des_min,hod,des_hod,zbytek_hod;
volatile bool read_flag=0;
uint8_t stav=0;

uint8_t i=0;


void main(void){
CLK_HSIPrescalerConfig(CLK_PRESCALER_HSIDIV1); // 16MHz z interního RC oscilátoru
init_milis(); // milis kvùli delay_ms()
init_tim1(); // nastavit a spustit timer
lcd_init();
lcd_clear();
GPIO_Init(GPIOG, GPIO_PIN_0, GPIO_MODE_OUT_PP_LOW_SLOW); // vıstup - "trigger pulz pro ultrazvuk"

enableInterrupts();  //globálnì povolí pøerušení
swi2c_init();
init_tim3(); // nastavit a spustit timer
zapis[0] = 0b00000000;
zapis[1] = 0b00001000;
zapis[2] = 0b00010101;//první pùlka desítky, druhá jednotky
//swi2c_write_buf(RTC_ADRESS,0x00,zapis,3);


  while (1){
		
		read_RTC();
		process_measurment(); // obsluhuje neblokujícím zpùsobem mìøení ultrazvukem
		
		
		if (read_flag){//zobrazení aktuálního èasu
			read_flag=0;
			sprintf(text,"time: %u%u:%u%u:%u%u",des_hod,hod,des_min,min,des_sec,sec);//
			lcd_gotoxy(0,1);
			lcd_puts(text);
		}
		
		if (milis()-time2>332){//zobrazení aktuální vzdálenosti
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
static uint16_t last_time=0;      // kadıch 100ms pøeète obsah RTC
  if(milis() - last_time >= 100){
    last_time = milis(); 
    error=swi2c_read_buf(RTC_ADRESS,0x00,RTC_precteno,7);
		
		sec = (RTC_precteno[0] & 0b00001111);              //sekundy
		des_sec = ((RTC_precteno[0] >> 4) & 0b00001111);		 //desítky sekund
		min = (RTC_precteno[1] & 0b00001111);		                //minuty
		des_min = ((RTC_precteno[1] >> 4) & 0b00001111);   //desítky minut
		hod = (RTC_precteno[2] & 0b00001111); 						//hodiny
		des_hod = ((RTC_precteno[2] >> 4) & 0b00000011);  //desítky hodin
		zbytek_hod = ((RTC_precteno[2] >> 4) & 0b00001111);   //zbytek dat hodin 
	}
}



void init_tim3(void){
TIM3_TimeBaseInit(TIM3_PRESCALER_16,1999); // clock 1MHz, strop 5000 => perioda pøeteèení 5 ms
TIM3_ITConfig(TIM3_IT_UPDATE, ENABLE); // povolíme pøerušení od update události (pøeteèení) timeru 3
TIM3_Cmd(ENABLE); // spustíme timer 3
}


INTERRUPT_HANDLER(TIM3_UPD_OVF_BRK_IRQHandler, 15){    //funkce pro obsluhu displejù
  TIM3_ClearITPendingBit(TIM3_IT_UPDATE);
	read_flag=1;
}


void process_measurment(void){
	static uint8_t stage=0; // stavovı automat
	static uint16_t time=0; // pro èasování pomocí milis
	switch(stage){
	case 0:	// èekáme ne uplyne  MEASURMENT_PERIOD abychom odstartovali mìøení
		if(milis()-time > MEASURMENT_PERIOD){
			time = milis(); 
			GPIO_WriteHigh(GPIOG,GPIO_PIN_0); // zahájíme trigger pulz
			stage = 1; // a bdueme èekat a uplyne èas trigger pulzu
		}
		break;
	case 1: // èekáme ne uplyne PULSE_LEN (generuje trigger pulse)
		if(milis()-time > PULSE_LEN){
			GPIO_WriteLow(GPIOG,GPIO_PIN_0); // ukonèíme trigger pulz
			stage = 2; // a pøejdeme do fáze kdy oèekáváme echo
		}
		break;
	case 2: // èekáme jestli dostaneme odezvu (èekáme na echo)
		if(TIM1_GetFlagStatus(TIM1_FLAG_CC2) != RESET){ // hlídáme zda timer hlásí zmìøení pulzu
			capture = TIM1_GetCapture2(); // uloíme vısledek mìøení
			capture_flag=1; // dáme vìdìt zbytku programu e máme novı platnı vısledek
			stage = 0; // a zaèneme znovu od zaèátku
		}else if(milis()-time > MEASURMENT_PERIOD){ // pokud timer nezachytil pulz po dlouhou dobu, tak echo nepøijde
			stage = 0; // a zaèneme znovu od zaèátku
		}		
		break;
	default: // pokud se cokoli pokazí
	stage = 0; // zaèneme znovu od zaèátku
	}	
}

void init_tim1(void){
GPIO_Init(GPIOC, GPIO_PIN_1, GPIO_MODE_IN_FL_NO_IT); // PC1 (TIM1_CH1) jako vstup
TIM1_TimeBaseInit(15,TIM1_COUNTERMODE_UP,0xffff,0); // timer necháme volnì bìet (do maximálního stropu) s èasovou základnou 1MHz (1us)
// Konfigurujeme parametry capture kanálu 1 - komplikované, nelze popsat v krátkém komentáøi
TIM1_ICInit(TIM1_CHANNEL_1,TIM1_ICPOLARITY_RISING,TIM1_ICSELECTION_DIRECTTI,TIM1_ICPSC_DIV1,0);
// Konfigurujeme parametry capture kanálu 2 - komplikované, nelze popsat v krátkém komentáøi
TIM1_ICInit(TIM1_CHANNEL_2,TIM1_ICPOLARITY_FALLING,TIM1_ICSELECTION_INDIRECTTI,TIM1_ICPSC_DIV1,0);
TIM1_SelectInputTrigger(TIM1_TS_TI1FP1); // Zdroj signálu pro Clock/Trigger controller 
TIM1_SelectSlaveMode(TIM1_SLAVEMODE_RESET); // Clock/Trigger má po pøíchodu signálu provést RESET timeru
TIM1_ClearFlag(TIM1_FLAG_CC2); // pro jistotu vyèistíme vlajku signalizující záchyt a zmìøení echo pulzu
TIM1_Cmd(ENABLE); // spustíme timer a bìí na pozadí
}


#ifdef USE_FULL_ASSERT
void assert_failed(u8* file, u32 line)
{ 

  while (1){}
}
#endif
