//======== My IP Physical Address ===================
#define ORG_BRAM_BASEADDRESS 0x43C10000		//ORG BRAM 
#define ORG_BRAM_SIZE 0x10000

//=========== IRQ number==================================
#define IRQ_NUM 61

//========== driver number ================================
#define IP_MAJOR		0     // 0: dynamic major number
#define IP_MINOR		0     // 0: dynamic minor number

//=========== include ======================================
#include <linux/interrupt.h>
#include <linux/sched.h>
#include <linux/kernel.h>
#include <linux/fs.h>                     //define file結構
#include <linux/types.h>
#include <linux/module.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/ioport.h>
#include <asm/uaccess.h>                  //copy from/to user
#include <linux/ioctl.h>
#include <asm/io.h>
#include <linux/slab.h>


//==================== IP address buffer=============//預先宣告變數除存記憶體映射位址 virtual address
volatile unsigned long *IP_ORG_vADDRESS; 


//=========================定義裝置編號===================================
static int IP_major = IP_MAJOR;  //主編號（類型編號）
static int IP_minor = IP_MINOR;  //次編號（同類型不同裝置）
module_param(IP_major, int, 0664);//設定存取模式,module_param(,,存取模式)
module_param(IP_minor, int, 0664);//設定存取模式,module_param(,,存取模式)

//===============define device structure=============================
static struct IP_Driver { //註冊字元裝置配置
    dev_t IP_devt;
    struct class *class;
    struct device *class_dev; //struct class_device *class_dev;
    struct cdev *cdev;
} IP;

//=============================file operation=========================
int i,j,k,a,b,c;
//-----reader struct-----------------------
static struct reader_struct { //read driver自定義DATA型態
  unsigned long org_datas[480][720];
  char time[23];//="2018,05,06,21,29,59,97\0";
} reader;

/*/-----writer struct------------------
static struct writer_struct { //write driver自定義DATA型態
  unsigned long svm_datas[15][7][36];
  unsigned long svm_datas_label[15][7][36];//代表svm正負(24bit),svm資料(23~0bit)
  unsigned long rho_data_label;
  unsigned long rho_data;
  unsigned long svm_label;
} writer;
*/

//int value = 0;
int result=0;



static int IP_open(struct inode *inode, struct file *file){
    return nonseekable_open(inode, file);
}

static int IP_release(struct inode *inode, struct file *file){

    return 0;
}

static int IP_read(struct file *file, char __user *buf, size_t size, loff_t *ppos){
    //-----ORG BRAM read-----------------------------------------
    ioread32(IP_ORG_vADDRESS + 0);// first send for delay one send
    for(a=0; a<480; a++) // read original video 64 x 128
      for(b=0; b<720; b++){
        reader.org_datas[a][b] = ioread32(IP_ORG_vADDRESS); //+ (a*720)+b+1 );
        mb();
      }

    result = copy_to_user(buf, &reader,size); //copy to user space
    return result;
}

static int IP_write(struct file *file,const char __user *buf, size_t size, loff_t *ppos){
/*
    result = copy_from_user(&writer, buf, size); //copy from user space

    switch(writer.svm_label){
      case 1 : IP_SVM_vADDRESS = IP_SVM0_vADDRESS; break;
      case 2 : IP_SVM_vADDRESS = IP_SVM1_vADDRESS; break;
      case 3 : IP_SVM_vADDRESS = IP_SVM2_vADDRESS; break;
      default : return result; break; //end here
    }

    //---- SVM module BRAM write--------------------------------------------------
    for(a=0; a<15; a++)   // write data
      for(b=0; b<7; b++)
        for(c=0; c<36; c++){
          iowrite32(writer.svm_datas_label[a][b][c]*16777216 +   //2^24為正負號表示
                    writer.svm_datas[a][b][c] ,     		 //svm整數表示
                    IP_SVM_vADDRESS+((a*7)+b));
          mb();
        }

    iowrite32( writer.rho_data_label*16777216  + 
               writer.rho_data                 ,  IP_RHO_vADDRESS + (int)writer.svm_label );//write rho data to fpga buffer
    mb();
*/
    return result;
}

static long IP_ioctl(struct file *file, unsigned int cmnd, unsigned long arg){
    return 0;
}

static struct file_operations IP_fops = {
    .owner          = THIS_MODULE,
    .open           = IP_open,
    .release        = IP_release,
    .read           = IP_read,
    .write          = IP_write,
    .unlocked_ioctl = IP_ioctl
};

//======================== cdev creat =============================
static int IP_setup_cdev(struct IP_Driver *IP_p){

    int ret, err;

    IP_p->IP_devt = MKDEV(IP_major,IP_minor); //向 kernel 取出 major/minor number

    if(IP_major){
	//register_chrdev_region 靜態取得 major number
        ret = register_chrdev_region(IP_p->IP_devt, 1, "IP-Driver");
    }else{
	//alloc_chrdev_region 動態取得 major number
        ret = alloc_chrdev_region(&IP_p->IP_devt, IP_minor, 1, "IP-Driver");
        IP_major = MAJOR(IP_p->IP_devt);//向 kernel 取出 major number
        IP_minor = MINOR(IP_p->IP_devt);//向 kernel 取出 minor number
    }
    if(ret <0)
        return ret;

    //--在「/sys/class/IP-Driver/IP-Driver/dev」新建立驅動程式資訊與規則檔---
    IP_p->class = class_create(THIS_MODULE, "IP-Driver");//登記 class , 讓驅動程式支援 udev
    if(IS_ERR(IP_p->class)){	//透過 IS_ERR() 來判斷class_create函式呼叫的成功與否
        printk("IP_setup_cdev: Can't create IP Driver class!\n");
        ret = PTR_ERR(IP_p->class);
        goto error1;
    }
    
    IP_p->cdev = cdev_alloc();//配置cdev的函式
    if(NULL == IP_p->cdev){
        printk("IP_setup_cdev: Can't alloc IP Driver cdev!\n");
        ret = -ENOMEM;
        goto error2;
    }
    
    IP_p->cdev->owner = THIS_MODULE;
    IP_p->cdev->ops = &IP_fops;

    err = cdev_add(IP_p->cdev, IP_p->IP_devt, 1);//向 kernel 登記驅動程式
    if(err){
        printk("IP_setup_cdev: Can't add IP cdev to system!\n");
        ret = -EAGAIN;
        goto error2;
    }

    //--建立「/sys/class/IP-Driver/IP-Driver」裝置名稱---
    IP_p->class_dev = device_create(IP_p->class, NULL, IP_p->IP_devt, NULL, "IP-Driver");

    if(IS_ERR(IP_p->class_dev)){ //透過 IS_ERR() 來判斷device_create函式呼叫的成功與否
        printk("IP_setup_cdev: Can't create IP class_dev to system!\n");
        ret = PTR_ERR(IP_p->class_dev);
        goto error3;
    }
    printk("IP-Driver_class_dev info: IP-Driver (%d:%d)\n",MAJOR(IP_p->IP_devt), MINOR(IP_p->IP_devt));
    
    return 0;

    error3:
        cdev_del(IP_p->cdev);
    error2:
        class_destroy(IP_p->class);
    error1:
        unregister_chrdev_region(IP_p->IP_devt, 1);
        return ret;
}
//==================== cdev Remove ===================================================
static void IP_remove_cdev(struct IP_Driver *IP_p){

    device_unregister(IP_p->class_dev);
    cdev_del(IP_p->cdev);
    class_destroy(IP_p->class);
    unregister_chrdev_region(IP_p->IP_devt, 1);
}

//===================== IP memory init =================================
static int IP_mem_init(volatile unsigned long **virtual_ADDRESS,resource_size_t IP_BASEADDRESS,resource_size_t SIZE){

    //printk("IP_virtual_address : %p, Size : %p\n", IP_BASEADDRESS, SIZE);
    //----request mem region---------------------------------------
    //保留位址範圍,(記憶體位址,byte單位的範圍大小,引數裝置名稱) holding IP physical address 
    if(!request_mem_region(IP_BASEADDRESS, SIZE,"IP_addr"))
    {
        printk("err:Request_mem_region\n");
        return -ENODEV;
    }
    //----ioremap_nocache----------------------------//記憶體映射,將實體address交給linux去分配
    *virtual_ADDRESS = (unsigned long *)ioremap_nocache(IP_BASEADDRESS, SIZE);

    printk("IP_physical_address: %p -> virtual_address: %p\n",(void *)IP_BASEADDRESS, *virtual_ADDRESS);

    return 0;
    
}
//===================== IP memory Remove =================================
static void IP_mem_remove(volatile unsigned long **virtual_ADDRESS,resource_size_t IP_BASEADDRESS,resource_size_t SIZE){
    //-----------remove ioremap_nocache------------------------
    iounmap((void *)*virtual_ADDRESS);//取消記憶體映射
    release_mem_region(IP_BASEADDRESS, SIZE);//取消物理記憶體位址保留
}

//====================== run intrrupt ============================
static irqreturn_t Intr_handler(int irq, void *dev_id){
    //unsigned int Rx_buffer = 0;
    printk("Intrrupt push!!!!!\n");
    //Rx_buffer = ioread32(IP_wBASEADDRESS);//+4);
    //printk("Buffer value = %c \n",Rx_buffer);
    return IRQ_HANDLED;
}

//======================= main code ============================================
static int IP_init(void){
    int ret=0;

    printk(KERN_ALERT "\n~~~helloworld cdev~~~\n");
    
  //------init cdev-------------------------------------------------------------------
    IP_setup_cdev(&IP); 						
    printk("Initional device finish~\n\n");  
    
  //------init IP memory----------------------------------------------------------------
    //note : IP_mem_init(&virtual address, physical address,physical address size)  
    IP_mem_init(&IP_ORG_vADDRESS,ORG_BRAM_BASEADDRESS,ORG_BRAM_SIZE); //ORG BRAM Read

    printk("Initional IP_mem finish~~\n\n");  

  //------init IRQ Interrupt------------------------------------------------------------
    ret = request_irq(IRQ_NUM,Intr_handler,0,"IP-Rx_ISR~",THIS_MODULE);	 
    if(ret < 0)
      pr_err("%s\n", "request_irq failed!!");
    else
      printk("Initional IRQ finish~~~\n");

    return ret;
}
static void IP_exit(void){
    printk(KERN_ALERT "\nClosing Modul...\n");
    
  //----remove IP memory-------------------------------------------------------------------------------
  //note : IP_mem_remove(&virtual address, physical address,physical address size)  
    IP_mem_remove(&IP_ORG_vADDRESS,ORG_BRAM_BASEADDRESS,ORG_BRAM_SIZE); //ORG BRAM Read

  //-----remove cdev-----------------------------------------------------------------------------
    IP_remove_cdev(&IP);						 

  //-----remove IRQ Interrupt-----------------------------------------------------------------------------
    free_irq(IRQ_NUM,THIS_MODULE);

    printk(KERN_ALERT "Finish Remove.\n");					  
}

module_init(IP_init);             /*模組安裝之啟動函式*/
module_exit(IP_exit);             /*模組卸載之啟動函式*/

MODULE_DESCRIPTION("IP Driver");  /*此程式介紹與描述*/
MODULE_LICENSE("GPL");            /*程式 License*/
