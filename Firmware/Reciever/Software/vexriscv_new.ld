ENTRY(_start)

MEMORY
{
	ROM (rx) : ORIGIN = 0x00000000, LENGTH = 32k
    RAM (w)  : ORIGIN = 0x80000000, LENGTH = 32k
}

SECTIONS
{
 
	.text :
	{
        __text_begin = .;
		*(.init)
        *(.text)
		*(.text*)
        . = ALIGN(4);
        PROVIDE(__text_end = .);
	} > ROM

    .rodata :
    {
        *(.rodata)          /* .rodata sections (constants, strings, etc.) */
        *(.rodata*)         /* .rodata* sections (constants, strings, etc.) */
        *(.srodata)
        *(.srodata*)
        PROVIDE(__rodata_end = .);
    } > ROM
   
	.data :
	{
		PROVIDE(__data_begin = .);
     /*   *(vtable) */
        
        *(.data)
		*(.data*)
        . = ALIGN(4);
		PROVIDE(__data_end = .);
		_edata = .;
		_end = .;
	} > RAM AT> ROM

	.bss :    
	{
        __bss_start = . ;
		__bss_begin = .;
		*(.bss*)
		*(.sbss)
        . = ALIGN(4);
		__bss_end = .;
	} > RAM

  
	__stack_top = ORIGIN(RAM) + LENGTH(RAM);

	/DISCARD/ :
	{
		*(.comment)
	}
}
