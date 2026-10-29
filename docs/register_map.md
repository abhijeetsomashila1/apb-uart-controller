# APB-UART Register Map

APB data width: 32 bits  
Register width: 32 bits  
Addressing: Byte addresses, aligned to 4 bytes

| Offset | Register | Access | Description |
|---|---|---|---|
| 0x00 | DATA | R/W | Write a byte to transmit; read the received byte |
| 0x04 | STATUS | R | Bit 0: TX busy; Bit 1: RX data available |
| 0x08 | CTRL | R/W | Bit 0: TX enable; Bit 1: RX enable |
| 0x0C | BAUD_DIV | R/W | Baud-rate divisor |
| 0x10 | VERSION | R | Design version, fixed at 0x00010000 |

## Register Details

### DATA — 0x00
- Bits [7:0] contain transmit or receive data.
- Writing DATA requests transmission of one byte.
- Reading DATA returns the most recently received byte.
- Other bits read as zero.

### STATUS — 0x04
- Bit 0: TX_BUSY — 1 while transmitting.
- Bit 1: RX_VALID — 1 while received data is available.
- Reading DATA clears RX_VALID when a valid byte is consumed.

### CTRL — 0x08
- Bit 0: TX_EN — enables transmission.
- Bit 1: RX_EN — enables reception.
- Reset value: 0x00000003.

### BAUD_DIV — 0x0C
- Reset value: 434.
- The UART baud rate is calculated as:
  baud_rate = clock_frequency / (16 × BAUD_DIV)
- A divisor of 434 at 50 MHz gives approximately 7200 baud under this oversampling formula.

### VERSION — 0x10
- Read-only.
- Reset-independent constant value: 0x00010000.

## Notes
- APB writes take effect only during a valid access phase with PSEL and PENABLE asserted and PREADY high.
- Unmapped addresses return zero.
- Reset is active-low.
