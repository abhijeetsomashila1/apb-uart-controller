# APB-UART Controller Specification

## 1. Overview
A memory-mapped UART peripheral controlled through an APB interface.

## 2. Initial Parameters
- Clock frequency: 50 MHz
- Default baud rate: 115200 baud
- UART format: 8 data bits, no parity, 1 stop bit (8-N-1)
- APB data width: 32 bits
- UART data width: 8 bits

## 3. Planned Features
- APB register read and write transactions
- UART transmit (TX)
- UART receive (RX)
- Configurable baud-rate divisor
- Transmit busy and receive-data status
- Self-checking simulation testbench

## 4. Verification Goals
- Verify APB setup and access phases
- Verify register reads and writes
- Verify UART TX start, data, and stop bits
- Verify UART RX data recovery
- Verify reset behavior and status flags

## 5. Implementation Status
- [ ] Specification finalized
- [ ] APB register interface
- [ ] UART transmitter
- [ ] UART receiver
- [ ] Self-checking testbench
- [ ] Assertions and corner-case tests
- [ ] Simulation results documented