#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <time.h>

#include <unistd.h>
#include <fcntl.h>
#include <math.h>


#define SOCKET_CNT_IP 	"192.168.1.11"
#define SOCKET_CNT_PORT 80

//-----driver variable----------
int IP_fd;

//-------view variable----------
int i,j,k,a,b,c;
int print_count = 0;

//-----socket send buffer-------
char send_buf[1382433]="test-successful!!!\0";	//send socket buffer

//-----reader data---------------------------
static struct reader_struct { //read driver自定義DATA型態
  unsigned long org_datas[480][720];
  char time[23];//="2018,05,06,21,29,59,97\0";
} reader;
//----------------------------------------


//========format transmission data=================================================================
int fmat_tdata(char *buffer,struct reader_struct *rds){ //buffer, reader struct (rds->)

 //----format now time---------------------------------------------------
  strcpy(rds-> time,"----,--,--,--,--,--,00\0"); //initional ','

  time_t now;
  time(&now);
  char now_chr[25];
  strcpy(now_chr,ctime(&now));

  *(rds-> time+0) = *(now_chr+20);//year
  *(rds-> time+1) = *(now_chr+21);
  *(rds-> time+2) = *(now_chr+22);
  *(rds-> time+3) = *(now_chr+23);
  
  char moon[4]="---";           //moon
  *(moon+0) = *(now_chr+4);
  *(moon+1) = *(now_chr+5);
  *(moon+2) = *(now_chr+6);

  if(strcmp("Jan",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+1; }
  if(strcmp("Feb",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+2; }
  if(strcmp("Mar",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+3; }
  if(strcmp("Apr",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+4; }
  if(strcmp("May",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+5; }
  if(strcmp("Jun",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+6; }
  if(strcmp("Jul",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+7; }
  if(strcmp("Aug",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+8; }
  if(strcmp("Sep",moon)==0){ *(rds-> time+5) = 48+0; *(rds-> time+6) = 48+9; }
  if(strcmp("Oct",moon)==0){ *(rds-> time+5) = 48+1; *(rds-> time+6) = 48+0; }
  if(strcmp("Nov",moon)==0){ *(rds-> time+5) = 48+1; *(rds-> time+6) = 48+1; }
  if(strcmp("Dec",moon)==0){ *(rds-> time+5) = 48+1; *(rds-> time+6) = 48+2; }

  *(rds-> time+8) = (*(now_chr+8)>=48 && *(now_chr+8)<=48+9)? *(now_chr+8) : 48+0;//day
  *(rds-> time+9) = *(now_chr+9);

  *(rds-> time+11) = *(now_chr+11);//hr
  *(rds-> time+12) = *(now_chr+12);

  *(rds-> time+14) = *(now_chr+14);//min
  *(rds-> time+15) = *(now_chr+15);

  *(rds-> time+17) = *(now_chr+17);//sec
  *(rds-> time+18) = *(now_chr+18);

  *(rds-> time+22) = 0;
  
 //---------init debug test data------------------------------------------
 // strcpy(rds-> time,"2018,05,06,21,29,59,97\0");


  ///printf("\n--- ORG init debug data ---\n");
  //for(a=0; a<480; a++)			//448+34022+5 ~	448+34022+4+128*64*4
  //  for(b=0; b<720; b++){
  //    rds-> org_datas[a][b]= b;
      ////printf("%c,",rds-> org_datas[a][b]);   //show org_datas
  //  }
 
 //---------format data buffer--------------------------------------------
    
  //time
  strcpy(buffer+0,"times=");		//0~5
  strcpy(buffer+6,rds-> time); 		//6~27
  *(buffer+28) = ';';			//28

  //ORG DATA
  strcpy(buffer+29,"org=");	//29 ~ 32
  for(a=0; a<480; a++)			//33 ~	33+480*720
    for(b=0; b<720; b++){
       *(buffer+33+0+((a*720*4)+(b*4))) = 48+(rds-> org_datas[a][b]/100%10);
       *(buffer+33+1+((a*720*4)+(b*4))) = 48+(rds-> org_datas[a][b]/10%10);
       *(buffer+33+2+((a*720*4)+(b*4))) = 48+(rds-> org_datas[a][b]%10);
       *(buffer+33+3+((a*720*4)+(b*4))) = ',';
    }
  *(buffer+32+1382400+1) = ';';	//33+480*720*4+1
  
  
  //------show buffer----------------
  ////printf("\n--- my data ---\n");
  ////for(i=0;i<strlen(buffer);i++)
    ////printf("%c",*(buffer+i));
  
  return 0;
}

int main(int argc, char *argv[]) {
//=============Socket client==================================================================
  int clientSocket, nBytes;//, portNum;
  struct sockaddr_in serverAddr;
  socklen_t addr_size;
 
 //------socket server initial----------------------------------------------
  //clientSocket = socket(PF_INET, SOCK_STREAM, 0);//TCP : PF_INET : protocol , AF_INIT : address
  //portNum = 80;
  serverAddr.sin_family = AF_INET;
  serverAddr.sin_port = htons(SOCKET_CNT_PORT);//(portNum);
  serverAddr.sin_addr.s_addr = inet_addr(SOCKET_CNT_IP);
  memset(serverAddr.sin_zero, '\0', sizeof serverAddr.sin_zero);  

  addr_size = sizeof serverAddr;
  //connect(clientSocket, (struct sockaddr *) &serverAddr, addr_size);



  //---- open file-------------
    int IP_fd;
    IP_fd = open("/dev/IP-Driver",O_RDWR);
    if(IP_fd == -1){
        perror("open device IP-Driver error!!\n");
        exit(1);
    }

  int send_times = atoi(*(argv+1));
  printf("send %d times.\n",send_times);
 for(i=0;i < send_times;i++){

  //---connect socket-------------
   clientSocket = socket(PF_INET, SOCK_STREAM, 0);
   connect(clientSocket, (struct sockaddr *) &serverAddr, addr_size);
  //------------------------------

  //---- read from kernel-------------
    if(read(IP_fd, &reader,sizeof(reader))){
      perror("read() error!\n");
      close(IP_fd);
      exit(1);
    }

 //-----show send data------------------------------------------------------
    //printf("Type a sentence to send to server:\n");
    fmat_tdata(send_buf,&reader);
    //printf("time!!@@@!!!!!!!!! : %s\n",reader.time);
    //printf("You typed: %s",send_buf);


  //-----send data------------------------------------------------------
    nBytes = strlen(send_buf) + 1;
    send(clientSocket,send_buf,nBytes,0);
    printf("successful send %d data!!\n",i);

    close(clientSocket);  //close socket
  }
    printf("\ntime!!@@@!!!!!!!!! : %s\n",reader.time);
    //printf("successful send data to server!!\n");

    
    close(IP_fd);

    return 0;
}
