
-- daca executia comenzii xp_cmdshell nu este posibila, datorita restrictiilor de securitate, 
-- se poate activa accesul folosind scriptul de mai jos
/*
exec sp_configure 'show advanced options', '1'
RECONFIGURE
exec sp_configure 'xp_cmdshell', '1' 
RECONFIGURE
*/


/*

CREATE TABLE [dbo].[Tasks](
	[TaskId] [int] IDENTITY(1,1) NOT NULL,
	[TaskName] [varchar](50) NULL,
	[TaskDate] [datetime] NULL,
	[TaskType] [varchar](20) NULL,
	[TaskProcessed] [char](1) NULL,
	[TaskParameters] [varchar](max) NULL,
 CONSTRAINT [PK_Tasks] PRIMARY KEY CLUSTERED 
(
	[TaskId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

insert into tasks (taskname, taskdate, tasktype, taskparameters) values ('NOTIFICARE-001', GETDATE(), 'notificare', 'atentie la dosar')
insert into tasks (taskname, taskdate, tasktype, taskparameters) values ('NOTIFICARE-002', GETDATE(), 'notificare', 'atentie la cerere')
insert into tasks (taskname, taskdate, tasktype, taskparameters) values ('FISIER-001', GETDATE(), 'fisier', 'c:\temp\alpha.txt')
insert into tasks (taskname, taskdate, tasktype, taskparameters) values ('PLATA-001', GETDATE(), 'plata', '100 lei pentru Ionescu')
insert into tasks (taskname, taskdate, tasktype, taskparameters) values ('INCASARE-001', GETDATE(), 'incasare', '100 lei de la Popescu')

*/

/*
TaskProcessed = 0 sau NULL - neprocesat
TaskProcessed = 1 - in lucru (se exporta in fisier)
TaskProcessed = 2 - exportat in fisier
TaskProcessed = 3 - trimis pe server
*/


---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ExportTasksToLegacySystem')
	DROP PROCEDURE ExportTasksToLegacySystem
GO


CREATE PROCEDURE ExportTasksToLegacySystem
	@output_folder AS VARCHAR(100),
	@output_format AS VARCHAR(3)
AS
BEGIN

	DECLARE @output_file AS VARCHAR(100)
	DECLARE @ret AS INT
	DECLARE @sql VARCHAR(8000)
	DECLARE @cmd VARCHAR(8000)

	SET @output_file = CONVERT(VARCHAR, GETDATE(), 120)
	SET @output_file = REPLACE(REPLACE(@output_file, ':', '-'), ' ', '-')
	SET @output_file = @output_file + '.' + @output_format

	UPDATE [Tasks] SET TaskProcessed = '1' WHERE ISNULL(TaskProcessed, '0')='0'

	SET @sql = '"SELECT * FROM [' + DB_NAME() + ']..[Tasks] WHERE TaskProcessed=''1'''

	IF @output_format = 'CSV' SET @sql = @sql + '"'
	IF @output_format = 'XML' SET @sql = @sql + ' FOR XML PATH(''Task'')"'

	SET @cmd = 'bcp ' + @sql + ' queryout ' + @output_folder + '\' + @output_file + ' -c -t, -T -S' + CONVERT(VARCHAR, SERVERPROPERTY('servername'))

	-- inregistrarile sunt exportate intr-un fisier extern
	EXEC @ret = master..xp_cmdshell @cmd

	IF @ret = 0 BEGIN
		-- inregistrarile au fost exportate in fisier
		UPDATE [Tasks] SET TaskProcessed = '2' WHERE TaskProcessed='1'

		SET @cmd = @output_folder + '\copy-to-server.bat ' + @output_folder + ' ' + @output_file

		EXEC @ret = master..xp_cmdshell @cmd
		IF @ret = 0 BEGIN
			-- fisierul a fost trimis la server (copiat prin share folder sau ftp)
			UPDATE [Tasks] SET TaskProcessed = '3' WHERE TaskProcessed='2'

			PRINT 'SUCCES'
		END ELSE BEGIN
			PRINT 'EROARE la trimitere fisier pe server'
		END
	END ELSE BEGIN
		PRINT 'EROARE la export fisier'
	END
END

GO

---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


/*

in directorul c:\temp\ se gaseste un fisier, copy-to-server.bat, care este apelat 
dupa exportul datelor in fisier pentru a trimite fisierul generat pe serverul destinatie
tot acolo trebuie pus si fisierul de parametrii ftp.params.txt

*/


UPDATE Tasks SET TaskProcessed = NULL

EXEC ExportTasksToLegacySystem 'c:\temp', 'CSV'

UPDATE Tasks SET TaskProcessed = NULL

EXEC ExportTasksToLegacySystem 'c:\temp', 'XML'
