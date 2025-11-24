# hello.s - RISC-V 64 位裸机程序, 打印 "hello world!" 到控制台

.section .text
.global _start
_start:
    # 0x80000000 <- OpenSBI
    # 0x80200000 <- hello.bin
    # 0x80210000 <- 栈顶
    
    # 设置栈指针
    li sp, 0x80210000
    
    # 调用打印函数
    call print_hello
    
    # 无限循环（退出 qemu 需要按 Ctrl+A X）
1:  j 1b

# 打印 "hello world!" 函数
print_hello:
    # 保存返回地址
    addi sp, sp, -8
    sd ra, 0(sp)
    
    # 加载字符串地址
    la a0, hello_string
    
    # 调用字符串打印函数
    call puts
    
    # 恢复返回地址
    ld ra, 0(sp)
    addi sp, sp, 8
    ret

# 字符串打印函数 void puts(char *str)
# a0: 字符串地址
puts:
    # 保存寄存器
    addi sp, sp, -16
    sd ra, 8(sp)
    sd s0, 0(sp)
    
    mv s0, a0  # 保存字符串地址

PRINT_LOOP:
    # 读取一个字符
    lb a0, 0(s0)
    beq a0, zero, PRINT_DONE  # 直到遇到 '\0' 结束
    
    # 调用字符打印函数
    call putc
    
    # 下一个字符
    addi s0, s0, 1
    j PRINT_LOOP

PRINT_DONE:
    # 恢复寄存器
    ld s0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret

# 字符打印函数 void putc(char c)
# a0: 要打印的字符
putc:
    # 使用 SBI 调用 (console_putchar)
    li a7, 0x01  # SBI_EXT_0_1_CONSOLE_PUTCHAR
    ecall
    ret

# 数据段
.section .rodata
hello_string:
    .asciz "\nHello RISC-V world!\n"

# 对齐到4字节边界
.align 2
