#include "../striVe_defs.h"

// --------------------------------------------------------

/*
	Memory Test
	It uses GPIO to flag the success or failure of the test
*/
unsigned int ints[50];
unsigned short shorts[50];
unsigned char bytes[50];

void main()
{
	int i;

	/* All GPIO pins are configured to be output */
	reg_gpio_data = 0;
	reg_gpio_ena =  0x0000;

	// start test
	reg_gpio_data = 0xA040;
	ints[0] = 0xDEAD2345;
	if(0xDEAD2345 != ints[0]) {reg_gpio_data = ints[0]&0xFFFF;reg_gpio_data = 0xAB40;}
	else reg_gpio_data = 0xAB41;

	reg_gpio_data = 0xA020;
	shorts[0] = 0xABCD;
	if(0xABCD != shorts[0]) reg_gpio_data = 0xAB20;
	else reg_gpio_data = 0xAB21;

	reg_gpio_data = 0xA010;
	bytes[0] = 0xA5;
	if(0xA5 != bytes[0]) reg_gpio_data = 0xAB10;
	else reg_gpio_data = 0xAB11;


/*
	for(i=0; i<10; i++)
		memory[i] = (i << 4);
	
	for(i=0; i<10; i++)
		if(memory[i] != (i << 4)) reg_gpio_data = 0xAB40;
		else reg_gpio_data = 0x0000;
	reg_gpio_data = 0xAB41;

	
	reg_gpio_data = 0xA020;
	int *p = (int *) memory;
	for(i=0; i<10; i++)
		p[i] = (i << 4);
	
	for(i=0; i<10; i++)
		if(p[i] != (i << 4)) reg_gpio_data = 0xAB20;
		else reg_gpio_data = 0xAB21;
	*/
	
}

