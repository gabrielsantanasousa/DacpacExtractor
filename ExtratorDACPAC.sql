if exists (select 1 from sys.all_objects where type = 'P' and name = 'prc_ExtratorDacPac')
begin
drop procedure prc_ExtratorDacPac
end
go

CREATE procedure prc_ExtratorDacPac

/*
AUTOR: Gabriel Santana Sousa
PROJETO: Extração de DACPAC automatizada
Procedure prc_ExtratorDacPac
Função: Extrair DACPAC de todos os bancos de dados ou do banco de dados selecionado

PARÂMETROS:
@localDestino
Função:
Define o local em disco de extração dos DACPACs
@localDestino = usp_ExtratorDacPac ' + char(39) + 'H:\Backup\Disk03\DIFF\' + char(39) + char(10) + char(10) +
'
@DBExtract
Função:
Define o nome do database que deseja extrair o DACPAC
@DBExtract = NomeDbEspecífico (Extrai o DACPAC somente do database informado)
@DBExtract = ALL (Extrai o DACPAC de todos os databases)
@InfoProc
Função:
Exibe o Help personalizado da procedure
@InfoProc = 1

@WhatIf
Função:
Exibide a descrição das ações que a procedure irá executar sem executa-las

@EmailProfile
Função:
Define o nome do profile de database email configurado para envio de email caso ocorram erros
@EmailProfile = ' + char(39) + 'DBAs' + char(39) + char(10) + 
'
@EmailRecipients
Função:
Define o e-mail que receberá o alerta
@EmailRecipients = ' + char(39) + 'dba@gssmsft.com' + char(39) + char(10) + 

DATA1 : 2023-11-03
AÇÃO1 : Criação

DATA2 : 2023-11-03
AÇÃO1 : inserido parâmetro @DBExtract para selecionar qual tipo de extração quer executar
*/

@localDestino varchar(120),
@DBExtract varchar(160),
@EmailRecipients varchar(1000),
@EmailProfile varchar(100),
@InfoProc bit = 0,
@WhatIf bit = 0
as  
begin
	SET NOCOUNT ON    
	DECLARE @COMANDO nvarchar(4000),
	@Banco varchar(160),
	@Disablexpcmdshell nvarchar(800),
	@Enablexpcmdshell nvarchar(800),
	@poshApagaArquivos nvarchar(800),
	@TituloEmail varchar(200),
	@MensagemEmail varchar(2000),
	@resultado int

	if @localDestino is null
	BEGIN
	PRINT '/-------------------------------------------/' + char(10) +
	'
	@localDestino
	Função:
	Define o local em disco de extração dos DACPACs
	@localDestino = usp_ExtratorDacPac ' + char(39) + 'H:\Backup\Disk03\DIFF\' + char(39) + char(10) + '
	Deve-se informar um local em disco para salvar o DACPAC
	'
	+ '/-------------------------------------------/'
	return 2
	END

	if @DBExtract is null
	BEGIN
	PRINT '/-------------------------------------------/' + char(10) +
	'
	@DBExtract
	Função:
	Define o nome do database que deseja extrair o DACPAC
	@DBExtract = NomeDbEspecífico (Extrai o DACPAC somente do database informado)
	@DBExtract = ALL (Extrai o DACPAC de todos os databases)
	'
	+ '/-------------------------------------------/'
	return 2
	END



	if @InfoProc = 1
	begin
	PRINT '----------------------------------------------------------------' + char(10) +
	'
	Procedure prc_ExtratorDacPac
	Função: Extrair DACPAC de todos os bancos de dados ou do banco de dados selecionado
	PARÂMETROS:
	@localDestino
	Função:
	Define o local em disco de extração dos DACPACs
	@localDestino = usp_ExtratorDacPac ' + char(39) + 'D:\Backup\Dacpac' + char(39) + char(10) + char(10) +
	'
	@DBExtract
	Função:
	Define o nome do database que deseja extrair o DACPAC
	@DBExtract = NomeDbEspecífico (Extrai o DACPAC somente do database informado)
	@DBExtract = ALL (Extrai o DACPAC de todos os databases)
	@InfoProc
	Função:
	Exibe o Help personalizado da procedure
	@InfoProc = 1
	
	@EmailProfile
	Função:
	Define o nome do profile de database email configurado para envio de email caso ocorram erros
	@EmailProfile = ' + char(39) + 'DBAs' + char(39) + char(10) + 
	'
	@EmailRecipients
	Função:
	Define o e-mail que receberá o alerta
	@EmailRecipients = ' + char(39) + 'dba@gssmsft.com' + char(39) + char(10) + 
	'
	@WhatIf
	Função:
	Exibide a descrição das ações que a procedure irá executar sem executa-las
	@WhatIf = 1' + char(10) + '----------------------------------------------------------------'
	RETURN 0 
	end

	set @Enablexpcmdshell =  'if (select value from sys.configurations where name = ' + char(39) + 'show advanced options' + char(39) + ') = 0' + char(10) +
	'exec sp_configure ' + char(39) + 'show advanced options' + char(39) + ',1' + char(10) +
	'RECONFIGURE with override;' + char(10) +
	'if (select value from sys.configurations where name = ' + char(39) + 'xp_cmdshell' + char(39) + ') = 0'  + char(10) +
	'exec sp_configure ' + char(39) + 'xp_cmdshell' + char(39) + ', 1' + char(10) +
	'RECONFIGURE with override;' + char(10) +
	'if (select value from sys.configurations where name = ' + char(39) + 'show advanced options' + char(39) + ') =1' + char(10) +
	'exec sp_configure ' + char(39) +  'show advanced options' + char(39) + ',0' + char(10) +
	'RECONFIGURE with override;'
	set @Disablexpcmdshell = 'if (select value from sys.configurations where name = ' + char(39) + 'show advanced options' + char(39) + ') =0' + char(10) +
	'exec sp_configure ' + char(39) + 'show advanced options' + char(39) + ',1' + char(10) +
	'RECONFIGURE with override;' + char(10) +
	'if (select value from sys.configurations where name = ' + char(39) + 'xp_cmdshell' + char(39) + ') = 1'  + char(10) +
	'exec sp_configure ' + char(39) + 'xp_cmdshell' + char(39) + ',0' + char(10) +
	'RECONFIGURE with override;' + char(10) +
	'exec sp_configure ' + char(39) +  'show advanced options' + char(39) + ',0' + char(10) +
	'RECONFIGURE with override;'
	
	if @DBExtract = 'ALL'
	begin
		SET @poshApagaArquivos = 'powershell -command "try {Get-ChildItem -Path ' + @localDestino + '*.dacpac | ForEach-Object {if ((Test-Path $_) -eq ' + char(39) + 'True' + char(39) + '){Remove-Item $_ -ErrorAction SilentlyContinue}}} catch {exit 2}"'
	end
	else
	begin
		SET @poshApagaArquivos = 'powershell -command "try {Get-ChildItem -Path ' + @localDestino + @DBExtract + '*.dacpac | ForEach-Object {if ((Test-Path $_) -eq ' + char(39) + 'True' + char(39) + '){Remove-Item $_ -ErrorAction SilentlyContinue}}} catch {exit 2}"'
	end
	--Cria tabela temporaria #tbDACPAC
	if object_id('tempdb..#tbDACPAC') is not null
	begin
		drop table #tbDACPAC
	end;

	create table #tbDACPAC  
	(  
		Banco varchar(160),
		cmd varchar(4000)  
	);

	--Cria tabela temporaria #tbDACPAC_erro
	if object_id('tempdb..#tbDACPAC_erro') is not null
	begin
		drop table #tbDACPAC_erro
	end;

	create table #tbDACPAC_erro  
	(  
		Banco varchar(160),
		cmd varchar(1000)
	);

	-- Insere na tabela #tbDACPAC o comando de para export dos dacpcs
	if @DBExtract = 'ALL'
	begin
		insert into #tbDACPAC  
		select name, 'C:\"Program Files"\"Microsoft SQL Server"\160\DAC\bin\SqlPackage.exe'+ ' /a:Extract /SourceTrustServerCertificate:"True" /p:IgnorePermissions=False /ssn:'+@@SERVERNAME+' /sdn:"'  + RTRIM(name)   
		+ '" /tf:"'  
		+ @localDestino  
		+ RTRIM(name)   
		+ '_'   
		+ CONVERT(char(8),getdate(),112)  
		+ '.dacpac" '  
		from sys.databases  
		where name not in ('master','tempdb','msdb','model')    
		and state_desc ='ONLINE';
		end
	else
	begin
		insert into #tbDACPAC  
		select name, 'C:\"Program Files"\"Microsoft SQL Server"\160\DAC\bin\SqlPackage.exe' + ' /a:Extract /SourceTrustServerCertificate:"True" /p:IgnorePermissions=False /ssn:'+@@SERVERNAME+' /sdn:"'  + RTRIM(name)   
		+ '" /tf:"'  
		+ @localDestino  
		+ RTRIM(name)   
		+ '_'   
		+ CONVERT(char(8),getdate(),112)  
		+ '.dacpac" '  
		from sys.databases  
		where name = @DBExtract
		and state_desc ='ONLINE';
	end

	if @WhatIf = 1
	begin
		print 'Habilita xp_cmdshell' + char(10)
		+ @Enablexpcmdshell + char(10) + char(10)
		+ 'Cria tabelas temporarias:' + char(10)+ 'create table #tbDACPAC' + char(10) + 'create table #tbDACPAC' + char(10)
		+ char(10) + 'Insere o comando de extração do DAPAC na tabela #tbDACPAC' + char(10)
		+ char(10) + '-- Alimenta variavel @poshApagaArquivos' + char(10) + 'SET @poshApagaArquivos = '  + @poshApagaArquivos
		+ char(10) + 'Comando variavel:' + char(10) + @poshApagaArquivos
		+ char(10) + char(10) + 'Apaga arquivos:' + char(10) + 'EXEC @resultado = xp_cmdshell @poshApagaArquivos' + char(10)
		+ char(10) + 'Executa extração dos DACPAC' + char(10)
		+  'C:\"Program Files"\"Microsoft SQL Server"\160\DAC\bin\SqlPackage.exe' + ' /a:Extract /SourceTrustServerCertificate:"True" /p:IgnorePermissions=False /ssn:'+@@SERVERNAME+' /sdn:"'
		+ char(10) + char(10)  + 'Desabilita xp_cmdshell' + char(10)
		+ @Disablexpcmdshell + char(10) + char(10)
		+ char(10) + 'FIM Whatif'
		return 0;
	end

	-- habilita xp_Cmdshell
	begin try
		waitfor delay '00:00:10'
		execute sp_executesql @Enablexpcmdshell
	end try
	begin catch
		print 'Erro no enable xp_cmdshell';
		Set @MensagemEmail = 'Instância: ' +  @@SERVERNAME + char(10) + 'ERRO Hablita xp_cmdshell'
		+ '<br>' + '<br>' + '<b>' + 'JOB ' + @@SERVERNAME + ': DBA_Extrator_DACPAC' + '</b>' + '</br>' +
		'<br>' + 'Error Message: ' + ERROR_MESSAGE() + '<br>' + '<br>' +
		'Email enviado pela procedue: prc_ExtratorDacPac'
		set @TituloEmail = 'ERRO Step Extrator DACPAC: ' + @@servername
		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = @EmailProfile,
		@body =  @MensagemEmail,
		@body_format ='HTML',
		@subject = @TituloEmail,
		@recipients =  @EmailRecipients;
		execute sp_executesql @Disablexpcmdshell;
		THROW;
		Return 2;
	end catch;

	-- Exclui arquivos dacpac existentes
	begin try
		waitfor delay '00:00:05'
		if (select value from sys.configurations where name = 'xp_cmdshell') = 0
		begin
		execute sp_executesql @Enablexpcmdshell;
		end
		EXEC @resultado = xp_cmdshell @poshApagaArquivos
		if @resultado = 2
		RAISERROR ('Erro na exclusão dos arquivos .dacpac', 16, 1);
	end try
	begin catch
		print 'Erro na exclusão dos arquivos .dacpac';
		Set @MensagemEmail = 'Instância: ' +  @@SERVERNAME + char(10) + 'Erro na exclusão dos arquivos .dacpac'
		+ '<br>' + '<br>' + '<b>' + 'JOB ' + @@SERVERNAME + ': DBA_Extrator_DACPAC' + '</b>' + '</br>' +
		'<br>' + 'Error Message: ' + ERROR_MESSAGE() + '<br>' + '<br>' +
		'Email enviado pela procedue: prc_ExtratorDacPac'
		set @TituloEmail = 'ERRO Step Extrator DACPAC: ' + @@servername
		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = @EmailProfile,
		@body =  @MensagemEmail,
		@body_format ='HTML',
		@subject = @TituloEmail,
		@recipients =  @EmailRecipients;
		execute sp_executesql @Disablexpcmdshell;
		THROW;
		Return 2;
	end catch;
	  
	-- Extrai dacpac
	DECLARE CUR_CMD CURSOR FOR   
	select Banco, cmd from #tbDACPAC order by 1 asc  
	OPEN CUR_CMD  
	FETCH NEXT FROM CUR_CMD INTO @Banco, @COMANDO
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		BEGIN TRY  
		if (select value from sys.configurations where name = 'xp_cmdshell') = 0
		begin
		execute sp_executesql @Enablexpcmdshell;
		end
		exec @resultado = xp_cmdshell @COMANDO
		if @resultado <> 0
		RAISERROR ('Erro na geração do DACPAC', 16, 1);
		END TRY  
		BEGIN CATCH  
		print 'Erro '+ @COMANDO
		insert into #tbDACPAC_erro values (@Banco,@COMANDO)
		END CATCH
		FETCH NEXT FROM CUR_CMD INTO @Banco, @COMANDO
		END  
	CLOSE CUR_CMD  
	DEALLOCATE CUR_CMD

	if exists (select 1 from #tbDACPAC_erro where banco is not null)
	begin
		select * from #tbDACPAC_erro
		RAISERROR ('Erro na geração de arquivo DACPAC, validação tabela #tbDACPAC_erro', 16, 1);
		Set @MensagemEmail = 'Instância: ' +  @@SERVERNAME + char(10) + 'Erro na extração de DACPAC'
		+ '<br>' + '<br>' + '<b>' + 'JOB ' + @@SERVERNAME + ': DBA_Extrator_DACPAC' + '</b>' + '</br>' +
		'Email enviado pela procedue: prc_ExtratorDacPac'
		set @TituloEmail = 'ERRO Step Extrator DACPAC: ' + @@servername
		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = @EmailProfile,
		@body =  @MensagemEmail,
		@body_format ='HTML',
		@subject = @TituloEmail,
		@recipients =  @EmailRecipients;
		execute sp_executesql @Disablexpcmdshell;
		if object_id('tempdb..#tbDACPAC') is not null
		begin
		drop table #tbDACPAC
		end;
		if object_id('tempdb..#tbDACPAC_erro') is not null
		begin
		drop table #tbDACPAC_erro
		end;
		Return 2;
	end
	-- Desabilita xp_Cmdshell
	execute sp_executesql @Disablexpcmdshell


	--Dropa tabelas temporárias
	if object_id('tempdb..#tbDACPAC') is not null
	begin
		drop table #tbDACPAC
	end;

	if object_id('tempdb..#tbDACPAC_erro') is not null
	begin
		drop table #tbDACPAC_erro
	end;

	end
go

/*

Exemplos de utilização


-- Parâmetro @whatif ativado, exibe descritivo da execuçõa, porém, não executa
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @DBExtract = 'ValidaDB', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @whatif = 1
go
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @DBExtract = 'ALL', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @whatif = 1
go

-- Parâmetro @InfoProc ativado, exibe help básico da procedure
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @DBExtract = 'ValidaDB', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @InfoProc = 1
go

--  @DBExtract = 'ALL', Executa extração de todos os bancos exceto master, model, msdb, tempdb
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @DBExtract = 'ALL'
go

--  @DBExtract = 'ValidaDB', Executa extração do banco informado ValidaDB exceto master, model, msdb, tempdb
exec prc_ExtratorDacPac @localDestino = 'D:\Backup\DACPAC\', @EmailProfile = 'DBA', @EmailRecipients = 'dba@gssmsft.com', @DBExtract = 'ValidaDB'
go

*/
