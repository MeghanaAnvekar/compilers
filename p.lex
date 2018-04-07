%{
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
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
                  ++i;
		  while(yytext[i] != '\n')
		  {
		  	if(yytext[i] == '%')
		  	{	
		  		macro_list[macro_count].body[j++] = '%';
		  		macro_list[macro_count].body[j++] = yytext[i];
		  	}
		  	else if(yytext[i] == '\\')
		  	{
		  		 macro_list[macro_count].body[j++] = '\\';
		  		 macro_list[macro_count].body[j++] = 'n';
		  	}
		  	else if(yytext[i] == '"')
		  	{
		  		macro_list[macro_count].body[j++] = '\\';
		  		macro_list[macro_count].body[j++] = yytext[i];
		  	}
		  	
		  	else
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
		
		strcat(path,argv[1]);

		int x = 0;
		param_file = fopen("param.txt","w");
		//param_file = fopen("p.txt","w");
		
		if(!param_file)
		{	printf("could not open param file");
			perror(param_path);
		}
		
		yyin = fopen(argv[1],"r");
		
		
		if(!yyin)
		{	printf("could not open file");
			perror(argv[1]);
		}
		else
		{
			char q[200];
			q[0] = '\0';
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
				strcat(q,";");
				strcat(q,macro_list[x].body);
				strcat(q,"$\n");
				
				fprintf(param_file,"%s",q);
				q[0] = '\0';
			}
		
			fclose(param_file);
		
			fclose(yyin);
			/*p1 = fopen(argv[1],"r");
			p2 = fopen(path,"w");
			
			char c;
			while((c = fgetc(p1))!= EOF)
			{
				fputc(c,p2);
			}
			
			fclose(p1);
			fclose(p2);*/
			in = fopen("custom_file.lex","w");
			
			fprintf(in,"%%{\n#include<stdio.h>\n#define ARG_MAX %d\n#define ARG_LENGTH %d\nFILE * out,* param_file;\ntypedef struct {\nchar param_list[ARG_MAX][ARG_LENGTH];\nint num_params;\n}node;\ntypedef struct{\nnode params;\nchar body[100];\n} macro_type; \nmacro_type macro_params[%d];\n%%}\n\n",ARG_MAX,ARG_LENGTH,macro_count);
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
			
			FILE * t = fopen("fill_macro_params","r");
			
			while(!feof(t))
			{
				char str[80];
				fgets(str,80,t);
				fprintf(in,"%s",str);
			}
			//fclose(t);
			//int charsToDelete = 2;
   			//fseeko(in,-charsToDelete,SEEK_END);
    			//int position = ftello(in);
    			//ftruncate(fileno(in), position);
			
		
			/*fprintf(in,"int main(argc,argv)\nint argc;\nchar ** argv;\n");
			fprintf(in,"{ \n\tparam_file = fopen(\"param.txt\",\"r\");\n\tint x = 0;\n\tmacro_type macro_params[%d];",macro_count);
			fprintf(in,"int num_macros = 0;\n\twhile(!feof(param_file))\n\t{	char str[80];\nint i =0;fgets(str,80,param_file);");
			fprintf(in,"\n\tprintf(\"Macro %%d\\n\",num_macros);\n\tif(str[0] != ';')\n\tif(str[0] != ';')\n\t{\n\tprintf(\"%%s\\n\",str);");
			fprintf(in,"\n\tint y =0;\n\twhile(str[i] !=';' )\n\t{int z = 0;\n\twhile(str[i] != ',' &&  str[i] != ';' && str[i] != '$')");
			fprintf(in,"\n\t{\n\tmacro_params[num_macros].params.param_list[y][z++] = str[i++];\n\t}");
			fprintf(in,"\n\tmacro_params[num_macros].params.param_list[y][z] = '\\0';\n\t++y;\n\tif(str[i] !=';')\n\t++i;\n\t}");
			fprintf(in,"macro_params[num_macros].params.num_params = y;\n\t}");
			fprintf(in,"else\n\tmacro_params[num_macros].params.num_params=0;\n\t");
			fprintf(in,"int p = 0;\n\t++i;");
			fprintf(in,"\t\nfor(;str[i] != '$'&&str[i] !='\\0';)\n\tmacro_params[num_macros].body[p++] = str[i++];\n\tmacro_params[num_macros].body[p] = '\\0';\n\tnum_macros++;\n\t}");*/

	fprintf(in,"\n\tout = stdout;\n\tyyin = fopen(\"%s\",\"r\");\n\tyylex();\n\tfclose(out);\n}",argv[1]);
	fclose(in);
		
		
			//system("flex output/custom.lex");
			//system("gcc output/lex.yy.c -lfl");
			//system("./output/a.out");
			
			}
		
				
		
	}
	
	return 0;
}
