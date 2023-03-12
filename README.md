
prc_ExtratorDacPac

Extração de DACPAC automatizada

Função: Extrair DACPAC de todos os bancos de dados ou do banco de dados selecionado

Exemplos de utilização

 - Parâmetro @whatif ativado, exibe descritivo da execuçõa, porém, não executa
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @DBExtract = 'ValidaDB', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @whatif = 1
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @DBExtract = 'ALL', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @whatif = 1

 - Parâmetro @InfoProc ativado, exibe help básico da procedure
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @DBExtract = 'ValidaDB', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @InfoProc = 1 

 - @DBExtract = 'ALL', Executa extração de todos os bancos exceto master, model, msdb, tempdb
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @DBExtract = 'ALL'
 
 - @DBExtract = 'ValidaDB', Executa extração do banco informado ValidaDB exceto master, model, msdb, tempdb
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @DBExtract = 'ValidaDB'


Requisitos:

  - SQL server 2016 ou posterior com database Mail configurado
