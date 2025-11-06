/*
 * simple kernel module to interact with ebpf
 *
 * todo: use argp
 *
 * */
#include <linux/uaccess.h>
#include <linux/fs.h>
#include <linux/proc_fs.h>
#include <linux/kernel.h> /* needed for pr_info() */
#include <linux/module.h> /* needed for all LKM */
#include <linux/printk.h> /* print info */
/*#include <printk.h> /* print info */


MODULE_AUTHOR("deomorxsy");
MODULE_DESCRIPTION("This LKM is part of the early libkjx library that aims to compare its tracing performance alongside libbpf.");

static int __init construct(void) {
    pr_info("kernel module was added.\n");
    return 0;
}

static void __exit destruct(void) {
    //printk(KERN_INFO "bye kernel!");*
    pr_info("kernel module removed.\n");
}


module_init(construct);
module_init(destruct);


MODULE_LICENSE("GPL");
