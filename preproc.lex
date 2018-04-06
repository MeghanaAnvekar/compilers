%{
#include <stdio.h>
#define SIZE 20
#define ARG_MAX 5
#define ARG_LENGTH 10

typedef struct{
int num_params;
char param_list[ARG_MAX][ARG_LENGTH]; 
}node;


typedef struct{

char name[20];
node params;
char body[100];
} macro_type;

macro_type macro_list[SIZE];
int macro_count = 0;
int j=0;
FILE * in,*p1,*p2,*param_file;

%}

MACRO "#define"+.*+"\n"

%%

{MACRO}      {    int i=0,j = 0;
		  
		  
		  macro_list[macro_count].params.num_params = 0;
		  		  
		  //skip #define
		  while( yytext[i++] != ' ');
		  
		  
		  while(yytext[i] != '(' && yytext[i] != ' ')
		    {
		      macro_list[macro_count].name[j++] = yytext[i];
		      
		      ++i;
		    }
		    macro_list[macro_count].name[j]='\0';
		  
                  
                  if(yytext[i] == '(')
                  {
                  	char temp[10];
                  	int k =0;
                  	++i;
                  	while(yytext[i] != ')')
                  	{
                  		if(yytext[i] != ',')
                  		{	while(yytext[i] == ' ')++i;
		          		while(yytext[i] != ','&& yytext[i] != ')')
		          		{
		          			
		          			temp[k++] = yytext[i++];
								          			
		          		}
		          		temp[k] = '\0';
		          		k =0;
		          		macro_list[macro_count].params.num_params++;
		          	}
		          	printf("%s\n",temp);
		          	strcpy(macro_list[macro_count].params.param_list[macro_list[macro_count].params.num_params - 1],temp);	
		          	if(yytext[i] != ')')
	          		++i;
		          	
                  	}
                  	
                  }
                  j = macro_list[macro_count].params.num_params;
                  for(;j < ARG_MAX;++j)
                  {
                  	strcpy(macro_list[macro_count].params.param_list[j],"\0");
                  }
                  
                  j = 0;
		  while(yytext[i] != '\n')
		  {
		      macro_list[macro_count].body[j++] = yytext[i];
		      ++i;
		      
		  }
                   macro_list[macro_count].body[j] = '\0';        
                 ++macro_count;
                      
                }
 .              {;}

%%

int main(argc, argv)
int argc;
char** argv;
{
	if(argc < 2)
	{
		printf("\nUsage : ./a.out c_file_name\n");
	}
	else
	{
		char path[30],param_path[30];
		strcat(path,"output/");
		strcat(param_path,"output/");
		strcat(path,argv[1]);
		strcat(param_path,"param.txt");
		int x = 0;
		param_file = fopen(param_path,"w");
		
		if(!param_file)
		printf("could not open param file");
		
		yyin = fopen(argv[1],"r");
		
		
		if(!yyin)
			printf("could not open file");
		else
		{
			char q[200];
			yylex();
			for(; x < macro_count;++x)
			{	int y;
				printf("\nMacro %d   ",x);
				for(y = 0; y < macro_list[x].params.num_params;++y)
					{
						printf("%s ",macro_list[x].params.param_list[y]);
						strcat(q,macro_list[x].params.param_list[y]);
						if(y != macro_list[x].params.num_params - 1)
							strcat(q,",");
					}
				strcat(q,";\n");
				fprintf(param_file,"%s",q);
			}
		
			fclose(param_file);
		
			fclose(yyin);
			p1 = fopen(argv[1],"r");
			p2 = fopen(path,"w");
			
			char c;
			while((c = fgetc(p1))!= EOF)
			{
				fputc(c,p2);
			}
			
			fclose(p1);
			fclose(p2);
			in = fopen("output/custom.lex","w");
		
			fprintf(in,"%%{\n#include<stdio.h>\n#define ARG_MAX %d\n#define ARG_LENGTH %d\nFILE * out,* param_file;\ntypedef struct {\nchar param_list[ARG_MAX][ARG_LENGTH];\nint num_params;\n}node;\nnode macro_params[%d]; \n%%}\n\n",ARG_MAX,ARG_LENGTH,macro_count);
			fprintf(in,"MACRO \"#define\"+.*+\"\\n\"\n");
			int i =0;
			for(;i < macro_count;++i)
			{
				fprintf(in,"MACRO%d   \"%s\"\n",i,macro_list[i].name);
			}
			fprintf(in,"%%%%\n");
		
			fprintf(in,"{MACRO}   {;}\n");
			fprintf(in,"\"printf(\"+.*+\"\\\",\"	 {fprintf(out,\"%%s\",yytext);}\n");
			 i =0;
			for(;i < macro_count;++i)
			{
				fprintf(in,"{MACRO%d}   { fprintf(out,\"%s\");}\n",i,macro_list[i].body);
			}
			fprintf(in,"\"\\n\"\t\t{fprintf(out,\"\\n\");}");
			fprintf(in,"\n. \t{fprintf(out,\"%%s\",yytext);}\n");
			fprintf(in,"%%%%\n");
		
			fprintf(in,"int main(argc,argv)\nint argc;\nchar ** argv;\n");
			fprintf(in,"{ \n\tparam_file = fopen(\"param.txt\",\"r\");\n\tint x = 0;\n\twhile(!feof(param_file))\n\t{\n\t\tfread(&macro_params[x],sizeof(node),1,param_file);++x;}\n\tout = fopen(\"output.c\",\"w\");\n\tyyin = fopen(\"%s\",\"r\");\n\tyylex();\n\tfclose(out);\n}",argv[1]);
		
		
			//system("flex output/custom.lex");
			//system("gcc output/lex.yy.c -lfl");
			//system("./output/a.out");
			/*
			int i =0;
			for(;i<macro_count;++i)
				printf("%s ; %s", macro_list[i].name,macro_list[i].body);*/
			
			}
		
				
		
	}
	
	return 0;
}
