--sql_server_health_check_v3.2.sql
--v3.2
--This is a non-intrusive script written to give an overall informational view of a 
--SQL Server instance for the purpose of first-time review.
--This script can be executed from within SSMS or using SQLCMD from the command line.
--
--Version 3.2 modifications
--Testing on SQL Server 2019
--Reworked some queries

/*
Information gathered
-Node name
-License information
-Product Version, level, and Edition
-Database properties
-Start time and up time
-Database listing
-Database uptime
-Database data and log size with total
-Database file size and growth settings
_Database file size free space
-Is this a Cluster Node?
-Nodes in Cluster
-Is AlwaysOn enabled (2012 and above)?
-AlwaysOn status
-Memory usage per database
-Memory usage of in-memory OLTP tables
-Last backup time per database
-No log backups for FULL or BULK_LOGGED recovery model databases in last 30 days
-Databases with no backups at all in the last 30 says
-Backups for the previous week per database
-Jobs that failed in the last 24 hours
-Missing indexes
-Duplicate indexes
-High index fragmentation check 
-Tables that have not had a stats update in more than 30 days and have significant changes
-Wait stats
-Users and roles
-Job information
-Existing linked server listing
-User statistics identification

*/


use master
GO


----------------------------------------------------------Node name

SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [CurrentNodeName];


----------------------------------------------------------Product Version, level, and Edition

SELECT SERVERPROPERTY('productversion') AS ProductVersion,
       SERVERPROPERTY ('productlevel') AS ProductLevel,
       SERVERPROPERTY ('edition') AS Edition;



----------------------------------------------------------License information

print N'License information';

SELECT SERVERPROPERTY('LicenseType') AS LICENSE_TYPE, 
ISNULL(SERVERPROPERTY('NumLicenses'),0) AS NUM_LICENCES;

----------------------------------------------------------Instance parameters

print N'Database Properties';


SELECT [Server_Name] = SERVERPROPERTY('servername'), 
       [SQL Version] = CASE
                           WHEN @@VERSION LIKE '%2000%8.%'
                           THEN '2000'
                           WHEN @@VERSION LIKE '%2005%9.%'
                           THEN '2005'
                           WHEN @@VERSION LIKE '%2008%10.0%'
                           THEN '2008'
                           WHEN @@VERSION LIKE '%2008 R2%10.5%'
                           THEN '2008 R2'
                           WHEN @@VERSION LIKE '%2012%11.%'
                           THEN '2012'
                           WHEN @@VERSION LIKE '%2014%12.%'
                           THEN '2014'
                           WHEN @@VERSION LIKE '%2016%13.%'
                           THEN '2016'
                           WHEN @@VERSION LIKE '%2017%14.%'
                           THEN '2017'
                           WHEN @@VERSION LIKE '%2019%15.%'
                           THEN '2019'
                       END, 
       [DB Name] = name, 
       [Status] = DATABASEPROPERTYEX(name, 'Status'), 
       [Updateability] = DATABASEPROPERTYEX(name, 'Updateability'), 
       [UserAccess] = DATABASEPROPERTYEX(name, 'UserAccess'), 
       [DB Owner] = SUSER_SNAME(sid), 
       [Collation] = DATABASEPROPERTYEX(name, 'Collation'), 
       [ComparisonStyle] = DATABASEPROPERTYEX(name, 'ComparisonStyle'), 
       [IsAnsiNullDefault] = CASE
                                 WHEN DATABASEPROPERTYEX(name, 'IsAnsiNullDefault') = 1
                                 THEN 'TRUE'
                                 WHEN DATABASEPROPERTYEX(name, 'IsAnsiNullDefault') = 0
                                 THEN 'FALSE'
                                 ELSE DATABASEPROPERTYEX(name, 'IsAnsiNullDefault')
                             END, 
       [IsAnsiNullsEnabled] = CASE
                                  WHEN DATABASEPROPERTYEX(name, 'IsAnsiNullsEnabled') = 1
                                  THEN 'TRUE'
                                  WHEN DATABASEPROPERTYEX(name, 'IsAnsiNullsEnabled') = 0
                                  THEN 'FALSE'
                                  ELSE DATABASEPROPERTYEX(name, 'IsAnsiNullsEnabled')
                              END, 
       [IsAnsiPaddingEnabled] = CASE
                                    WHEN DATABASEPROPERTYEX(name, 'IsAnsiPaddingEnabled') = 1
                                    THEN 'TRUE'
                                    WHEN DATABASEPROPERTYEX(name, 'IsAnsiPaddingEnabled') = 0
                                    THEN 'FALSE'
                                    ELSE DATABASEPROPERTYEX(name, 'IsAnsiPaddingEnabled')
                                END, 
       [IsAnsiWarningsEnabled] = CASE
                                     WHEN DATABASEPROPERTYEX(name, 'IsAnsiWarningsEnabled') = 1
                                     THEN 'TRUE'
                                     WHEN DATABASEPROPERTYEX(name, 'IsAnsiWarningsEnabled') = 0
                                     THEN 'FALSE'
                                     ELSE DATABASEPROPERTYEX(name, 'IsAnsiWarningsEnabled')
                                 END, 
       [IsArithmeticAbortEnabled] = CASE
                                        WHEN DATABASEPROPERTYEX(name, 'IsArithmeticAbortEnabled') = 1
                                        THEN 'TRUE'
                                        WHEN DATABASEPROPERTYEX(name, 'IsArithmeticAbortEnabled') = 0
                                        THEN 'FALSE'
                                        ELSE DATABASEPROPERTYEX(name, 'IsArithmeticAbortEnabled')
                                    END, 
       [IsAutoClose] = CASE
                           WHEN DATABASEPROPERTYEX(name, 'IsAutoClose') = 1
                           THEN 'TRUE'
                           WHEN DATABASEPROPERTYEX(name, 'IsAutoClose') = 0
                           THEN 'FALSE'
                           ELSE DATABASEPROPERTYEX(name, 'IsAutoClose')
                       END, 
       [IsAutoCreateStatistics] = CASE
                                      WHEN DATABASEPROPERTYEX(name, 'IsAutoCreateStatistics') = 1
                                      THEN 'TRUE'
                                      WHEN DATABASEPROPERTYEX(name, 'IsAutoCreateStatistics') = 0
                                      THEN 'FALSE'
                                      ELSE DATABASEPROPERTYEX(name, 'IsAutoCreateStatistics')
                                  END, 
       [IsAutoCreateStatisticsIncremental] = CASE
                                                 WHEN DATABASEPROPERTYEX(name, 'IsAutoCreateStatisticsIncremental') = 1
                                                 THEN 'TRUE'
                                                 WHEN DATABASEPROPERTYEX(name, 'IsAutoCreateStatisticsIncremental') = 0
                                                 THEN 'FALSE'
                                                 ELSE '*** Feature Supported from SQL 2014****'
                                             END, 
       [IsAutoShrink] = CASE
                            WHEN DATABASEPROPERTYEX(name, 'IsAutoShrink') = 1
                            THEN 'TRUE'
                            WHEN DATABASEPROPERTYEX(name, 'IsAutoShrink') = 0
                            THEN 'FALSE'
                            ELSE DATABASEPROPERTYEX(name, 'IsAutoShrink')
                        END, 
       [IsAutoUpdateStatistics] = CASE
                                      WHEN DATABASEPROPERTYEX(name, 'IsAutoUpdateStatistics') = 1
                                      THEN 'TRUE'
                                      WHEN DATABASEPROPERTYEX(name, 'IsAutoUpdateStatistics') = 0
                                      THEN 'FALSE'
                                      ELSE DATABASEPROPERTYEX(name, 'IsAutoUpdateStatistics')
                                  END, 
       [IsClone] = CASE
                       WHEN DATABASEPROPERTYEX(name, 'IsClone') = 1
                       THEN 'TRUE'
                       WHEN DATABASEPROPERTYEX(name, 'IsClone') = 0
                       THEN 'FALSE'
                       ELSE '*** Feature Supported from SQL 2014****'
                   END, 
       [IsCloseCursorsOnCommitEnabled] = CASE
                                             WHEN DATABASEPROPERTYEX(name, 'IsCloseCursorsOnCommitEnabled') = 1
                                             THEN 'TRUE'
                                             WHEN DATABASEPROPERTYEX(name, 'IsCloseCursorsOnCommitEnabled') = 0
                                             THEN 'FALSE'
                                             ELSE DATABASEPROPERTYEX(name, 'IsCloseCursorsOnCommitEnabled')
                                         END, 
       [IsFulltextEnabled] = CASE
                                 WHEN DATABASEPROPERTYEX(name, 'IsFulltextEnabled') = 1
                                 THEN 'TRUE'
                                 WHEN DATABASEPROPERTYEX(name, 'IsFulltextEnabled') = 0
                                 THEN 'FALSE'
                                 ELSE DATABASEPROPERTYEX(name, 'IsFulltextEnabled')
                             END, 
       [IsInStandBy] = CASE
                           WHEN DATABASEPROPERTYEX(name, 'IsInStandBy') = 1
                           THEN 'TRUE'
                           WHEN DATABASEPROPERTYEX(name, 'IsInStandBy') = 0
                           THEN 'FALSE'
                           ELSE DATABASEPROPERTYEX(name, 'IsInStandBy')
                       END, 
       [IsLocalCursorsDefault] = CASE
                                     WHEN DATABASEPROPERTYEX(name, 'IsLocalCursorsDefault') = 1
                                     THEN 'TRUE'
                                     WHEN DATABASEPROPERTYEX(name, 'IsLocalCursorsDefault') = 0
                                     THEN 'FALSE'
                                     ELSE DATABASEPROPERTYEX(name, 'IsLocalCursorsDefault')
                                 END, 
       [IsMemoryOptimizedElevateToSnapshotEnabled] = CASE
                                                         WHEN DATABASEPROPERTYEX(name, 'IsMemoryOptimizedElevateToSnapshotEnabled') = 1
                                                         THEN 'TRUE'
                                                         WHEN DATABASEPROPERTYEX(name, 'IsMemoryOptimizedElevateToSnapshotEnabled') = 0
                                                         THEN 'FALSE'
                                                         ELSE '*** Feature Supported from SQL 2014****'
                                                     END, 
       [IsMergePublished] = CASE
                                WHEN DATABASEPROPERTYEX(name, 'IsMergePublished') = 1
                                THEN 'TRUE'
                                WHEN DATABASEPROPERTYEX(name, 'IsMergePublished') = 0
                                THEN 'FALSE'
                                ELSE DATABASEPROPERTYEX(name, 'IsMergePublished')
                            END, 
       [IsNullConcat] = CASE
                            WHEN DATABASEPROPERTYEX(name, 'IsNullConcat') = 1
                            THEN 'TRUE'
                            WHEN DATABASEPROPERTYEX(name, 'IsNullConcat') = 0
                            THEN 'FALSE'
                            ELSE DATABASEPROPERTYEX(name, 'IsNullConcat')
                        END, 
       [IsNumericRoundAbortEnabled] = CASE
                                          WHEN DATABASEPROPERTYEX(name, 'IsNumericRoundAbortEnabled') = 1
                                          THEN 'TRUE'
                                          WHEN DATABASEPROPERTYEX(name, 'IsNumericRoundAbortEnabled') = 0
                                          THEN 'FALSE'
                                          ELSE DATABASEPROPERTYEX(name, 'IsNumericRoundAbortEnabled')
                                      END, 
       [IsParameterizationForced] = CASE
                                        WHEN DATABASEPROPERTYEX(name, 'IsParameterizationForced') = 1
                                        THEN 'TRUE'
                                        WHEN DATABASEPROPERTYEX(name, 'IsParameterizationForced') = 0
                                        THEN 'FALSE'
                                        ELSE DATABASEPROPERTYEX(name, 'IsParameterizationForced')
                                    END, 
       [IsPublished] = CASE
                           WHEN DATABASEPROPERTYEX(name, 'IsPublished') = 1
                           THEN 'TRUE'
                           WHEN DATABASEPROPERTYEX(name, 'IsPublished') = 0
                           THEN 'FALSE'
                           ELSE DATABASEPROPERTYEX(name, 'IsPublished')
                       END, 
       [IsQuotedIdentifiersEnabled] = CASE
                                          WHEN DATABASEPROPERTYEX(name, 'IsQuotedIdentifiersEnabled') = 1
                                          THEN 'TRUE'
                                          WHEN DATABASEPROPERTYEX(name, 'IsQuotedIdentifiersEnabled') = 0
                                          THEN 'FALSE'
                                          ELSE DATABASEPROPERTYEX(name, 'IsQuotedIdentifiersEnabled')
                                      END, 
       [IsRecursiveTriggersEnabled] = CASE
                                          WHEN DATABASEPROPERTYEX(name, 'IsRecursiveTriggersEnabled') = 1
                                          THEN 'TRUE'
                                          WHEN DATABASEPROPERTYEX(name, 'IsRecursiveTriggersEnabled') = 0
                                          THEN 'FALSE'
                                          ELSE DATABASEPROPERTYEX(name, 'IsRecursiveTriggersEnabled')
                                      END, 
       [IsSubscribed] = CASE
                            WHEN DATABASEPROPERTYEX(name, 'IsSubscribed') = 1
                            THEN 'TRUE'
                            WHEN DATABASEPROPERTYEX(name, 'IsSubscribed') = 0
                            THEN 'FALSE'
                            ELSE DATABASEPROPERTYEX(name, 'IsSubscribed')
                        END, 
       [IsSyncWithBackup] = CASE
                                WHEN DATABASEPROPERTYEX(name, 'IsSyncWithBackup') = 1
                                THEN 'TRUE'
                                WHEN DATABASEPROPERTYEX(name, 'IsSyncWithBackup') = 0
                                THEN 'FALSE'
                                ELSE DATABASEPROPERTYEX(name, 'IsSyncWithBackup')
                            END, 
       [IsTornPageDetectionEnabled] = CASE
                                          WHEN DATABASEPROPERTYEX(name, 'IsTornPageDetectionEnabled') = 1
                                          THEN 'TRUE'
                                          WHEN DATABASEPROPERTYEX(name, 'IsTornPageDetectionEnabled') = 0
                                          THEN 'FALSE'
                                          ELSE DATABASEPROPERTYEX(name, 'IsTornPageDetectionEnabled')
                                      END, 
       [IsVerifiedClone] = CASE
                               WHEN DATABASEPROPERTYEX(name, 'IsVerifiedClone') = 1
                               THEN 'TRUE'
                               WHEN DATABASEPROPERTYEX(name, 'IsVerifiedClone') = 0
                               THEN 'FALSE'
                               ELSE '*** Feature Supported from SQL 2016****'
                           END, 
       [IsXTPSupported] = CASE
                              WHEN DATABASEPROPERTYEX(name, 'IsXTPSupported') = 1
                              THEN 'TRUE'
                              WHEN DATABASEPROPERTYEX(name, 'IsXTPSupported') = 0
                              THEN 'FALSE'
                              ELSE '*** Feature Supported from SQL 2016****'
                          END, 
       [IsXTPSupported] = CASE
                              WHEN DATABASEPROPERTYEX(name, 'IsXTPSupported') = 1
                              THEN 'TRUE'
                              WHEN DATABASEPROPERTYEX(name, 'IsXTPSupported') = 0
                              THEN 'FALSE'
                              ELSE '*** Feature Supported from SQL 2016****'
                          END, 
       [LastGoodCheckDbTime] = CASE
                                   WHEN DATABASEPROPERTYEX(name, 'LastGoodCheckDbTime') IS NULL
                                   THEN '*** Feature Supported from SQL 2016****'
                                   ELSE DATABASEPROPERTYEX(name, 'LastGoodCheckDbTime')
                               END, 
       [LCID] = DATABASEPROPERTYEX(name, 'LCID'), 
       [Recovery] = DATABASEPROPERTYEX(name, 'Recovery'), 
       [SQLSortOrder] = DATABASEPROPERTYEX(name, 'SQLSortOrder'), 
       [Version] = DATABASEPROPERTYEX(name, 'Version')
FROM master.sys.sysdatabases;


----------------------------------------------------------Database listing

print N'Database list with Status and Recovery Model';

SELECT substring(name,1,40) AS name,  substring(state_desc,1,20) AS STATE, 
substring(recovery_model_desc,1,20) AS RECOVERY_MODEL
   FROM sys.databases
order by name;

----------------------------------------------------------Database startup time

print N'Start time';

SELECT DATEADD(ms,-sample_ms,GETDATE() )AS StartTime
FROM sys.dm_io_virtual_file_stats(1,1);


----------------------------------------------------------Database start time uptime

print N'Up time';


DECLARE @server_start_time DATETIME,
@seconds_diff INT,
@years_online INT,
@days_online INT,
@hours_online INT,
@minutes_online INT,
@seconds_online INT ;

SELECT @server_start_time = login_time
FROM master.sys.sysprocesses
WHERE spid = 1 ;

SELECT @seconds_diff = DATEDIFF(SECOND, @server_start_time, GETDATE()),
@years_online = @seconds_diff / 31536000,
@seconds_diff = @seconds_diff % 31536000,
@days_online = @seconds_diff / 86400,
@seconds_diff = @seconds_diff % 86400,
@hours_online = @seconds_diff / 3600,
@seconds_diff = @seconds_diff % 3600,
@minutes_online = @seconds_diff / 60,
@seconds_online = @seconds_diff % 60 ;

SELECT @server_start_time AS server_start_time,
@years_online AS years_online,
@days_online AS days_online,
@hours_online AS hours_online,
@minutes_online AS minutes_online,
@seconds_online AS seconds_online ;


--SELECT substring(name,1,40) AS name,  substring(state_desc,1,20) AS STATE, 
--substring(recovery_model_desc,1,20) AS RECOVERY_MODEL
--   FROM sys.databases
--order by name;

----------------------------------------------------------Database data and log size with total

print N'Data and Log Size with Total';


with fs
as
(
    select database_id, type, size * 8.0 / 1024 size
    from sys.master_files
)
select 
    name,
    (select sum(size) from fs where type = 0 and fs.database_id = db.database_id) DataFileSizeMB,
    (select sum(size) from fs where type = 1 and fs.database_id = db.database_id) LogFileSizeMB,
    (select sum(size) from fs where type = 0 and fs.database_id = db.database_id) +
    (select sum(size) from fs where type = 1 and fs.database_id = db.database_id) AS Total_MB
from sys.databases db;

--Grand total of ALL data and log files as one value (in 8KB pages)
select SUM(size*8.0)/1024 AS Total_MB, sum(size*8.0)/1024/1024 AS Total_GB,
sum(size*8.0)/1024/1024/1024 AS Total_TB 
from sys.master_files;


----------------------------------------------------------Database file size and growth settings

print N'Size and Growth Settings';


select substring(b.name,1,40) AS DB_Name, substring(a.name,1,40) AS Logical_name, 
substring(a.filename,1,100) AS File_Name,
cast((a.size * 8.00) / 1024 as numeric(12,2)) as DB_Size_in_MB,
case when a.growth > 100 then 'In MB' else 'In Percentage' end File_Growth,
cast(case when a.growth > 100 then (a.growth * 8.00) / 1024
else (((a.size * a.growth) / 100) * 8.00) / 1024
end as numeric(12,2)) File_Growth_Size_in_MB,
case when ( maxsize = -1 or maxsize=268435456 ) then 'AutoGrowth Not Restricted' else 'AutoGrowth Restricted' end AutoGrowth_Status
from sysaltfiles a
join sysdatabases b on a.dbid = b.dbid
where DATABASEPROPERTYEX(b.name, 'status') = 'ONLINE'
order by b.name;


----------------------------------------------------------Database file size free space

DECLARE @command VARCHAR(5000) 
SELECT @command = 'Use [' + '?' + '] SELECT 
@@servername as ServerName, 
' + '''' + '?' + '''' + ' AS DatabaseName , name 
, convert(decimal(12,2),round(a.size/128.000,2)) as FileSizeMB 
, convert(decimal(12,2),round(fileproperty(a.name,'+''''+'SpaceUsed'+''''+')/128.000,2)) as SpaceUsedMB 
, convert(decimal(12,2),round((a.size-fileproperty(a.name,'+''''+'SpaceUsed'+''''+'))/128.000,2)) as FreeSpaceMB, 
CAST(100 * (CAST (((a.size/128.0 -CAST(FILEPROPERTY(a.name,' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(a.size/128.0)) AS decimal(4,2))) AS varchar(8)) + ' + '''' + '%' + '''' + ' AS FreeSpacePct 
from sys.database_files a' 

EXEC sp_MSForEachDB @command 

--Reset to master DB
use master
GO

----------------------------------------------------------Is this a Cluster Node?

SELECT 'Clustered', case when SERVERPROPERTY('IsClustered') = 0 then 'No'
else 'Yes' end;

----------------------------------------------------------Nodes in Cluster

print N'Cluster Nodes';

SELECT * FROM fn_virtualservernodes();


----------------------------------------------------------Is AlwaysOn enabled (2012 and above)?


SELECT 'AlwaysOn', case when SERVERPROPERTY('IsHadrEnabled') = 0 then 'No'
                        when SERVERPROPERTY('IsHadrEnabled') = 1 then 'Yes'
                        end;


----------------------------------------------------------AlwaysOn status

declare @c int;
declare @rd nvarchar(60); 
declare @osd nvarchar(60);
declare @rhd nvarchar(60); 
declare @shd nvarchar(60); 
declare @csd nvarchar(60);
select @c = COUNT(name) 
from sys.all_objects
where name = 'dm_hadr_availability_replica_states';
if @c = 0
print N'No AlwaysOn Status';
else
select @rd = role_desc, @osd= case when operational_state_desc is null then 'Replica is not local'
                  else operational_state_desc end,
       @rhd = recovery_health_desc, @shd = synchronization_health_desc,
       @csd = connected_state_desc
from sys.dm_hadr_availability_replica_states;
print @rd
print @osd
print @rhd
print @shd
print @csd
  
	

----------------------------------------------------------Memory usage per database

print N'Memory Usage per User Database';


SELECT 
                substring(DB_NAME(database_id),1,40) AS [Database Name]
                ,COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
FROM 
                sys.dm_os_buffer_descriptors
WHERE 
                database_id > 4 
                AND database_id <> 32767
                AND db_name(database_id) <> 'SSISDB'
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC OPTION (RECOMPILE);



----------------------------------------------------------Memory usage of in-memory OLTP tables

print N'In-memory OLTP table usage';
				      SELECT object_name(object_id) AS Name, *  
				      FROM sys.dm_db_xtp_table_memory_stats;


----------------------------------------------------------Last backup time per database

SELECT substring(sdb.Name,1,40) AS DatabaseName,
COALESCE(CONVERT(VARCHAR(12), MAX(bus.backup_finish_date), 101),'-') AS LastBackUpTime
FROM sys.sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
where sdb.Name <> 'tempdb'
GROUP BY sdb.Name;


----------------------------------------------------------No log backups for FULL or BULK_LOGGED recovery model databases in last 30 days


print N'Databases with FULL or BULK_LOGGED recovery model and no log backups in last 30 days';


SELECT name AS at_risk_database
   FROM sys.databases
where recovery_model_desc in('FULL','BULK_LOGGED')
and name not in(
SELECT 
msdb.dbo.backupset.database_name AS DBName 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 30)
and msdb..backupset.type = 'L'
group by msdb.dbo.backupset.database_name
);


----------------------------------------------------------Databases with no backups at all in the last 30 says

print N'Databases with NO backups in last 30 days';

SELECT name AS at_risk_database
   FROM sys.databases
where name <> 'tempdb'
and name not in(
SELECT 
substring(msdb.dbo.backupset.database_name,1,40) AS DBName 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 30)
group by msdb.dbo.backupset.database_name
);


----------------------------------------------------------Backups for the previous week per database

print N'All backups for previous week';

SELECT 
CONVERT(CHAR(40), SERVERPROPERTY('Servername')) AS Server, 
substring(msdb.dbo.backupset.database_name,1,40) AS DBName, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log'
WHEN 'F' THEN 'File'
WHEN 'P' THEN 'Partial'
WHEN 'I' THEN 'Differential database'
WHEN 'G' THEN 'Differential file'
WHEN 'Q' THEN 'Differential partial'
WHEN NULL THEN msdb..backupset.type 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
substring(msdb.dbo.backupmediafamily.logical_device_name,1,50) AS logical_device_name, 
substring(msdb.dbo.backupmediafamily.physical_device_name,1,50) AS physical_device_name, 
substring(msdb.dbo.backupset.name,1,50) AS backupset_name, 
substring(msdb.dbo.backupset.description,1,50) AS description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
ORDER BY 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_finish_date;


----------------------------------------------------------Jobs that failed in the last 24 hours

print N'Jobs Failing in last 24 hours';

----------------------------------------------------------Variable Declarations

DECLARE @PreviousDate datetime
DECLARE @Year VARCHAR(4)
DECLARE @Month VARCHAR(2)
DECLARE @MonthPre VARCHAR(2)
DECLARE @Day VARCHAR(2)
DECLARE @DayPre VARCHAR(2)
DECLARE @FinalDate INT

----------------------------------------------------------Initialize Variables

SET @PreviousDate = DATEADD(dd, -1, GETDATE()) --Last 1 day
SET @Year = DATEPART(yyyy, @PreviousDate)
SELECT @MonthPre = CONVERT(VARCHAR(2), DATEPART(mm, @PreviousDate))
SELECT @Month = RIGHT(CONVERT(VARCHAR, (@MonthPre + 1000000000)),2)
SELECT @DayPre = CONVERT(VARCHAR(2), DATEPART(dd, @PreviousDate))
SELECT @Day = RIGHT(CONVERT(VARCHAR, (@DayPre + 1000000000)),2)
SET @FinalDate = CAST(@Year + @Month + @Day AS INT)
--Final Logic
SELECT substring(j.[name],1,40) AS JOB,
substring(s.step_name,1,40) AS Step,
h.step_id,
substring(h.step_name,1,40) AS Step,
h.run_date,
h.run_time,
h.sql_severity,
substring(h.message,1,100) AS Message,
h.server
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j
ON h.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobsteps s
ON j.job_id = s.job_id AND h.step_id = s.step_id
WHERE h.run_status = 0 --Failure
AND h.run_date > @FinalDate
ORDER BY h.instance_id DESC;



----------------------------------------------------------Missing indexes

print N'Missing Indexes';


SELECT substring(so.name,1,40) AS Name
, (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) as Impact
, ddmid.equality_columns
, ddmid.inequality_columns
, ddmid.included_columns
FROM sys.dm_db_missing_index_group_stats AS ddmigs
INNER JOIN sys.dm_db_missing_index_groups AS ddmig
ON ddmigs.group_handle = ddmig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS ddmid
ON ddmig.index_handle = ddmid.index_handle
INNER JOIN sys.objects so WITH (nolock)
ON ddmid.object_id = so.object_id
WHERE ddmigs.group_handle IN (
SELECT TOP (5000) group_handle
FROM sys.dm_db_missing_index_group_stats WITH (nolock)
ORDER BY (avg_total_user_cost * avg_user_impact)*(user_seeks+user_scans)DESC);



----------------------------------------------------------Duplicate indexes

print N'Duplicate Indexes';

DECLARE @SCHEMANAME VARCHAR(30);
DECLARE @TABLENAME VARCHAR(127);
WITH ind_list AS(
  select o.schema_id, i.object_id, i.index_id,
    i.name, i.type_desc,
    i.is_unique, i.is_primary_key, 
    STUFF( (SELECT ',' + tc.name
            FROM sys.index_columns ic
              JOIN sys.columns tc
               ON tc.column_id = ic.column_id AND
                  tc.object_id = ic.object_id
            WHERE ic.object_id = i.object_id AND
                  ic.index_id = i.index_id 
              AND ic.is_included_column = 0
            ORDER BY ic.index_column_id
            FOR XML PATH ('') ),1,1,'' ) index_columns,
    STUFF( (SELECT ',' + tc.name
            FROM sys.index_columns ic
              JOIN sys.columns tc
               ON tc.column_id = ic.column_id AND
                  tc.object_id = ic.object_id
            WHERE ic.object_id = i.object_id AND
                  ic.index_id = i.index_id
               AND ic.is_included_column = 1
            ORDER BY ic.index_column_id
            FOR XML PATH ('') ),1,1,'' ) include_columns
  FROM sys.indexes i
    JOIN sys.objects o ON o.object_id = i.object_id
  WHERE i.index_id > 0 AND i.type_desc <> 'XML'
    AND object_name(i.object_id) LIKE @TABLENAME
    AND i.is_disabled = 0 
    AND schema_name(o.schema_id) LIKE @SCHEMANAME )
SELECT substring(schema_name(included_indexes.schema_id),1,30) AS owner, 
  object_name(included_indexes.object_id) table_name,
  (SELECT SUM(st.row_count) FROM sys.dm_db_partition_stats st
   WHERE st.object_id = included_indexes.object_id
     AND st.index_id < 2 ) num_rows,
  included_indexes.name included_index_name, 
  included_indexes.index_columns included_index_columns, 
  included_indexes.include_columns
       included_index_include_columns,
  included_indexes.type_desc included_index_type, 
  included_indexes.is_unique included_index_uniqueness,
  included_indexes.is_primary_key included_index_PK,
  (SELECT SUM(a.total_pages) * 8 FROM sys.allocation_units a
    JOIN sys.partitions p ON a.container_id = p.partition_id
   WHERE p.object_id = included_indexes.object_id AND
     p.index_id = included_indexes.index_id
  ) included_index_size_kb,
  including_indexes.name including_index_name, 
  including_indexes.index_columns including_index_columns, 
  including_indexes.include_columns
       including_index_include_columns,
  including_indexes.type_desc including_index_type, 
  including_indexes.is_unique including_index_uniqueness,
  including_indexes.is_primary_key including_index_PK,
  (SELECT SUM(a.total_pages) * 8 FROM sys.allocation_units a
     JOIN sys.partitions p ON a.container_id = p.partition_id
   WHERE p.object_id = including_indexes.object_id AND
    p.index_id = including_indexes.index_id
  ) including_index_size_kb
FROM ind_list included_indexes
  JOIN ind_list including_indexes
    ON including_indexes.object_id = included_indexes.object_id
  JOIN sys.partitions ing_p 
   ON ing_p.object_id = including_indexes.object_id AND
      ing_p.index_id = including_indexes.index_id
  JOIN sys.allocation_units ing_a
   ON ing_a.container_id = ing_p.partition_id
WHERE including_indexes.index_id <> included_indexes.index_id
  AND LEN(included_indexes.index_columns) <=
      LEN(including_indexes.index_columns) 
  AND included_indexes.index_columns + ',' =
      SUBSTRING(including_indexes.index_columns,1,
              LEN(included_indexes.index_columns + ','))
ORDER BY 2 DESC;



----------------------------------------------------------High index fragmentation check 

print N'Index with HIGH Fragmentation (equal to or greater than 30 percent)';

EXEC sp_MSforeachdb '
USE [?]
SELECT ''?'' AS DB_NAME,
QUOTENAME(sysind.name) AS [index_name],
indstat.*
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, ''LIMITED'')
AS indstat
INNER JOIN sys.indexes sysind ON indstat.object_id = sysind.object_id AND
indstat.index_id = sysind.index_id
where avg_fragmentation_in_percent >= 30
ORDER BY avg_fragmentation_in_percent DESC;
'
--Reset to master DB
use master
GO


-----------------Tables that have not had a stats update in more than 30 days and have significant changes

print N'Tables with NO statistical update in the last 30 days';

EXEC sp_MSforeachdb '
USE [?]
IF ''?'' <> ''master'' AND ''?'' <> ''model'' AND ''?'' <> ''msdb'' AND ''?'' <> ''tempdb''
SELECT ''?'' AS DB_NAME,obj.name, obj.object_id, stat.name, stat.stats_id, last_updated, modification_counter  
FROM sys.objects AS obj   
INNER JOIN sys.stats AS stat ON stat.object_id = obj.object_id  
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
WHERE obj.type = ''U''
AND last_updated < getdate() - 30 
AND modification_counter > 1000
--OR last_updated IS NULL;
'

----------------------------------------------------------Wait stats

print N'Wait Stats';

SELECT *
FROM sys.dm_os_wait_stats
where wait_time_ms > 10000
ORDER BY wait_time_ms DESC;


----------------------------------------------------------Users and roles

print N'Users and Roles';

WITH Roles_CTE(Role_Name, Username)
AS
(
	SELECT 
		User_Name(sm.[groupuid]) as [Role_Name],
		user_name(sm.[memberuid]) as [Username]
	FROM [sys].[sysmembers] sm
)

SELECT  
    Roles_CTE.Role_Name,
    [DatabaseUserName] = princ.[name],
    [UserType] = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                    WHEN 'G' THEN 'Windows Group'
                    WHEN 'A' THEN 'Application Role'
                    WHEN 'R' THEN 'Database Role'
                    WHEN 'C' THEN 'User mapped to a certificate'
                    WHEN 'K' THEN 'User mapped to an asymmetric key'
                 END
FROM 
    sys.database_principals princ 
JOIN Roles_CTE on Username = princ.name
where princ.type in ('S', 'U', 'G', 'A', 'R', 'C', 'K')
ORDER BY princ.name;


----------------------------------------------------------Job information

print N'Job Information';


SELECT	 [JobName] = [jobs].[name]
		,[Category] = [categories].[name]
		,[Owner] = SUSER_SNAME([jobs].[owner_sid])
		,[Enabled] = CASE [jobs].[enabled] WHEN 1 THEN 'Yes' ELSE 'No' END
		,[Scheduled] = CASE [schedule].[enabled] WHEN 1 THEN 'Yes' ELSE 'No' END
		,[Description] = [jobs].[description]
		,[Occurs] = 
				CASE [schedule].[freq_type]
					WHEN   1 THEN 'Once'
					WHEN   4 THEN 'Daily'
					WHEN   8 THEN 'Weekly'
					WHEN  16 THEN 'Monthly'
					WHEN  32 THEN 'Monthly relative'
					WHEN  64 THEN 'When SQL Server Agent starts'
					WHEN 128 THEN 'Start whenever the CPU(s) become idle' 
					ELSE ''
				END
		,[Occurs_detail] = 
				CASE [schedule].[freq_type]
					WHEN   1 THEN 'O'
					WHEN   4 THEN 'Every ' + CONVERT(VARCHAR, [schedule].[freq_interval]) + ' day(s)'
					WHEN   8 THEN 'Every ' + CONVERT(VARCHAR, [schedule].[freq_recurrence_factor]) + ' weeks(s) on ' + 
						LEFT(
							CASE WHEN [schedule].[freq_interval] &  1 =  1 THEN 'Sunday, '    ELSE '' END + 
							CASE WHEN [schedule].[freq_interval] &  2 =  2 THEN 'Monday, '    ELSE '' END + 
							CASE WHEN [schedule].[freq_interval] &  4 =  4 THEN 'Tuesday, '   ELSE '' END + 
							CASE WHEN [schedule].[freq_interval] &  8 =  8 THEN 'Wednesday, ' ELSE '' END + 
							CASE WHEN [schedule].[freq_interval] & 16 = 16 THEN 'Thursday, '  ELSE '' END + 
							CASE WHEN [schedule].[freq_interval] & 32 = 32 THEN 'Friday, '    ELSE '' END + 
							CASE WHEN [schedule].[freq_interval] & 64 = 64 THEN 'Saturday, '  ELSE '' END , 
							LEN(
								CASE WHEN [schedule].[freq_interval] &  1 =  1 THEN 'Sunday, '    ELSE '' END + 
								CASE WHEN [schedule].[freq_interval] &  2 =  2 THEN 'Monday, '    ELSE '' END + 
								CASE WHEN [schedule].[freq_interval] &  4 =  4 THEN 'Tuesday, '   ELSE '' END + 
								CASE WHEN [schedule].[freq_interval] &  8 =  8 THEN 'Wednesday, ' ELSE '' END + 
								CASE WHEN [schedule].[freq_interval] & 16 = 16 THEN 'Thursday, '  ELSE '' END + 
								CASE WHEN [schedule].[freq_interval] & 32 = 32 THEN 'Friday, '    ELSE '' END + 
								CASE WHEN [schedule].[freq_interval] & 64 = 64 THEN 'Saturday, '  ELSE '' END 
							) - 1
						)
					WHEN  16 THEN 'Day ' + CONVERT(VARCHAR, [schedule].[freq_interval]) + ' of every ' + CONVERT(VARCHAR, [schedule].[freq_recurrence_factor]) + ' month(s)'
					WHEN  32 THEN 'The ' + 
							CASE [schedule].[freq_relative_interval]
								WHEN  1 THEN 'First'
								WHEN  2 THEN 'Second'
								WHEN  4 THEN 'Third'
								WHEN  8 THEN 'Fourth'
								WHEN 16 THEN 'Last' 
							END +
							CASE [schedule].[freq_interval]
								WHEN  1 THEN ' Sunday'
								WHEN  2 THEN ' Monday'
								WHEN  3 THEN ' Tuesday'
								WHEN  4 THEN ' Wednesday'
								WHEN  5 THEN ' Thursday'
								WHEN  6 THEN ' Friday'
								WHEN  7 THEN ' Saturday'
								WHEN  8 THEN ' Day'
								WHEN  9 THEN ' Weekday'
								WHEN 10 THEN ' Weekend Day' 
							END + ' of every ' + CONVERT(VARCHAR, [schedule].[freq_recurrence_factor]) + ' month(s)' 
					ELSE ''
				END
		,[Frequency] = 
				CASE [schedule].[freq_subday_type]
					WHEN 1 THEN 'Occurs once at ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_start_time]), 6), 5, 0, ':'), 3, 0, ':')
					WHEN 2 THEN 'Occurs every ' + 
								CONVERT(VARCHAR, [schedule].[freq_subday_interval]) + ' Seconds(s) between ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_start_time]), 6), 5, 0, ':'), 3, 0, ':') + ' and ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_end_time]), 6), 5, 0, ':'), 3, 0, ':')
					WHEN 4 THEN 'Occurs every ' + 
								CONVERT(VARCHAR, [schedule].[freq_subday_interval]) + ' Minute(s) between ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_start_time]), 6), 5, 0, ':'), 3, 0, ':') + ' and ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_end_time]), 6), 5, 0, ':'), 3, 0, ':')
					WHEN 8 THEN 'Occurs every ' + 
								CONVERT(VARCHAR, [schedule].[freq_subday_interval]) + ' Hour(s) between ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_start_time]), 6), 5, 0, ':'), 3, 0, ':') + ' and ' + 
								STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [schedule].[active_end_time]), 6), 5, 0, ':'), 3, 0, ':')
					ELSE ''
				END
		,[AvgDurationInSec] = CONVERT(DECIMAL(10, 2), [jobhistory].[AvgDuration])
		,[Next_Run_Date] = 
				CASE [jobschedule].[next_run_date]
					WHEN 0 THEN CONVERT(DATETIME, '1900/1/1')
					ELSE CONVERT(DATETIME, CONVERT(CHAR(8), [jobschedule].[next_run_date], 112) + ' ' + 
						 STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [jobschedule].[next_run_time]), 6), 5, 0, ':'), 3, 0, ':'))
				END
FROM	 [msdb].[dbo].[sysjobs] AS [jobs] WITh(NOLOCK) 
		 LEFT OUTER JOIN [msdb].[dbo].[sysjobschedules] AS [jobschedule] WITh(NOLOCK) 
				 ON [jobs].[job_id] = [jobschedule].[job_id] 
		 LEFT OUTER JOIN [msdb].[dbo].[sysschedules] AS [schedule] WITh(NOLOCK) 
				 ON [jobschedule].[schedule_id] = [schedule].[schedule_id] 
		 INNER JOIN [msdb].[dbo].[syscategories] [categories] WITh(NOLOCK) 
				 ON [jobs].[category_id] = [categories].[category_id] 
		 LEFT OUTER JOIN 
					(	SELECT	 [job_id], [AvgDuration] = (SUM((([run_duration] / 10000 * 3600) + 
																(([run_duration] % 10000) / 100 * 60) + 
																 ([run_duration] % 10000) % 100)) * 1.0) / COUNT([job_id])
						FROM	 [msdb].[dbo].[sysjobhistory] WITh(NOLOCK)
						WHERE	 [step_id] = 0 
						GROUP BY [job_id]
					 ) AS [jobhistory] 
				 ON [jobhistory].[job_id] = [jobs].[job_id];


----------------------------------------------------------Existing linked server listing


print N'Linked Server Information';


declare @x int;
select @x = COUNT(name) 
from sys.all_objects
where name = 'Servers';
if @x <> 0
SELECT  
c.name, provider, data_source, is_remote_login_enabled, b.modify_date
FROM sys.Servers a
LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
where a.server_id <> 0;
else
exec sp_linkedservers;


----------------------------------------------------------User statistics identification

print N'User statistics';

select s.name as STATS_NAME, SCHEMA_NAME(ob.Schema_id) AS SCHEMA_NAME, OBJECT_NAME(s.object_id) AS TABLE_NAME
FROM sys.stats s
INNER JOIN sys.Objects ob ON ob.Object_id = s.object_id
WHERE SCHEMA_NAME(ob.Schema_id) <> 'sys'
AND Auto_Created = 0 AND User_Created = 1;


