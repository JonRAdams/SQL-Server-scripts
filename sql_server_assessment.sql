--sql_server_assessment.sql
--Lists the resources and their usage for a single SQL Server instance
--Intended to act as a tool for migrations to other hardware or the cloud.
--NOTE - Comment out the invalid query under the physical memory section if
--       based on the current SQL Server version.
--Includes routine at the end to measure CPU and IOPS per hour for 24-hour period.

use master
GO


----------------------------------------------------------Node name

SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [CurrentNodeName];


----------------------------------------------------------Product Version, level, and Edition

SELECT
  CASE 
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '8%' THEN 'SQL2000'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '9%' THEN 'SQL2005'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.0%' THEN 'SQL2008'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.5%' THEN 'SQL2008 R2'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '11%' THEN 'SQL2012'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '12%' THEN 'SQL2014'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '13%' THEN 'SQL2016'     
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '14%' THEN 'SQL2017' 
     ELSE 'unknown'
  END AS MajorVersion,
  SERVERPROPERTY('ProductLevel') AS ProductLevel,
  SERVERPROPERTY('Edition') AS Edition,
  SERVERPROPERTY('ProductVersion') AS ProductVersion
  
  

----------------------------------------------------------License information

print N'License information';

SELECT SERVERPROPERTY('LicenseType') AS LICENSE_TYPE, 
ISNULL(SERVERPROPERTY('NumLicenses'),0) AS NUM_LICENCES;


----------------------------------------------------------Database listing

print N'Database list with Status and Recovery Model';


----------------------------------------------------------Logical CPUs


select cpu_count as logical_cpu_count
from sys.dm_os_sys_info;


----------------------------------------------------------Physical Memory

--For SQL Server version 2008, 2008R2
select physical_memory_in_bytes/1024/1024/1024 as GB
from sys.dm_os_sys_info;

--For SQL Server version > 2008
select physical_memory_kb/1024/1024 as GB
from sys.dm_os_sys_info;


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



----------------------------------------------------------Database file size and growth settings

print N'Size and Growth';


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

----------------------------------------------------------Database data and log file total size


SELECT
    SUM(CASE WHEN type = 0 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) + 
    SUM(CASE WHEN type = 1 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) AS Total_GB 
FROM
    sys.master_files MF
    JOIN sys.databases DB ON DB.database_id = MF.database_id
WHERE DB.source_database_id is null; 

----------------------------------------------------------Full backup size by Database

WITH 
   MostRecentBackups
   AS(
      SELECT
         database_name AS [Database],
         MAX(bus.backup_finish_date) AS LastBackupTime,
         CASE bus.type
            WHEN 'D' THEN 'Full'
         END AS Type
      FROM msdb.dbo.backupset bus
      WHERE bus.type <> 'F'
      GROUP BY bus.database_name,bus.type
   ),
   BackupsWithSize
   AS(
      SELECT
	mrb.*,
	(SELECT TOP 1 CONVERT(DECIMAL(10,2), b.compressed_backup_size/1024/1024) AS backup_size FROM msdb.dbo.backupset b WHERE [Database] = b.database_name AND LastBackupTime = b.backup_finish_date) AS [Backup Size],
	(SELECT TOP 1 DATEDIFF(s, b.backup_start_date, b.backup_finish_date) FROM msdb.dbo.backupset b WHERE [Database] = b.database_name AND LastBackupTime = b.backup_finish_date) AS [Seconds],
        (SELECT TOP 1 b.media_set_id FROM msdb.dbo.backupset b WHERE [Database] = b.database_name AND LastBackupTime = b.backup_finish_date) AS media_set_id
      FROM MostRecentBackups mrb
   )
SELECT
    d.name AS [Database],
    d.state_desc AS State,
    bf.LastBackupTime AS [LastFull],
    DATEDIFF(DAY,bf.LastBackupTime,GETDATE()) AS [TimeSinceLastFullInDays],
    bf.[Backup Size] AS [FullBackupSizeInMB],
    bf.Seconds AS [FullBackupSecondsToComplete],
    CASE WHEN DATEDIFF(DAY,bf.LastBackupTime,GETDATE()) > 14 THEN NULL ELSE (SELECT TOP 1 bmf.physical_device_name FROM msdb.dbo.backupmediafamily bmf WHERE bmf.media_set_id = bf.media_set_id AND bmf.device_type = 2) END AS [FullBackupLocalPath],     
	(SELECT CONVERT(DECIMAL(10,2),SUM(size)*8.0/1024) AS size FROM sys.master_files WHERE type = 0 AND d.name = DB_NAME(database_id)) AS DataFileSize,
    (SELECT CONVERT(DECIMAL(10,2),SUM(size)*8.0/1024) AS size FROM sys.master_files WHERE type = 1 AND d.name = DB_NAME(database_id)) AS LogFileSize
FROM sys.databases d
LEFT JOIN BackupsWithSize bf ON (d.name = bf.[Database] AND (bf.Type = 'Full' OR bf.Type IS NULL))
WHERE d.name <> 'tempdb' AND d.source_database_id IS NULL
ORDER BY d.name;


----------------------------------------------------------License feature usage


IF OBJECT_ID('tempdb.dbo.##enterprise_features') IS NOT NULL
  DROP TABLE ##enterprise_features
 
CREATE TABLE ##enterprise_features
  (
     dbname       SYSNAME,
     feature_name VARCHAR(100),
     feature_id   INT
  )
 
EXEC sp_msforeachdb
N' USE [?] 
IF (SELECT COUNT(*) FROM sys.dm_db_persisted_sku_features) >0 
BEGIN 
   INSERT INTO ##enterprise_features 
    SELECT dbname=DB_NAME(),feature_name,feature_id 
    FROM sys.dm_db_persisted_sku_features 
END '
SELECT *
FROM   ##enterprise_features;

----------------------------------------------------------CPU and IOPS for 24 hours (avg. work day or end of month)
/*
create table #CPU (snap_time varchar(30),
		           row_num int,
		           db_name varchar(50),
		           cpu_ms int,
		           cpu_pct int)
		
create table #IOPS (snap_time varchar(30),
		    db_id int,
		    db_name varchar(50),
		    reads int,
		    writes int,
		    total_io int)

declare @cntr int
set @cntr = 0
while (@cntr) < 2    --set number of 1-hour loops to perform here. 
begin;

WITH DB_CPU_Stats
AS
(
    SELECT convert(varchar, getdate(), 120) AS ts, 
	  DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], 
      SUM(total_worker_time) AS [CPU_Time_Ms]
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY (
                    SELECT CONVERT(int, value) AS [DatabaseID] 
                  FROM sys.dm_exec_plan_attributes(qs.plan_handle)
                  WHERE attribute = N'dbid') AS F_DB
    GROUP BY DatabaseID
)
insert into #CPU (row_num,snap_time,db_name,cpu_ms,cpu_pct)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
       ts, DatabaseName,
        [CPU_Time_Ms], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
--WHERE DatabaseID > 4 -- system databases
--AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION (RECOMPILE);

WITH D 
AS(
	SELECT 
		convert(varchar, getdate(), 120) AS ts,
		database_id,DB_NAME(database_id) AS Name, 
		SUM(num_of_reads) AS IO_Reads,
		SUM(num_of_writes) AS IO_Writes,
		SUM(num_of_reads + num_of_writes) AS Total_IO
	FROM sys.dm_io_virtual_file_stats(NULL, NULL) 
	GROUP BY database_id,DB_NAME(database_id))
insert into #IOPS (snap_time,db_id,db_name,reads,writes,total_io)
SELECT 
	D.ts, D.database_id, D.Name,
	SUM(D.IO_Reads) - SUM(L.num_of_reads) AS Data_Reads,
	SUM(D.IO_Writes) - SUM(L.num_of_writes) AS Data_Writes,
	SUM(D.IO_Reads+D.IO_Writes) - SUM(L.num_of_reads+L.num_of_writes) AS Total_IO
	FROM D
JOIN sys.dm_io_virtual_file_stats(NULL, 2) L
	ON D.database_id = L.database_id
GROUP BY D.ts,D.database_id, D.Name
ORDER BY D.database_id;

  waitfor delay '01:00:00'    --change this to determine the interval between snapshots
  set @cntr = @cntr + 1

end

select db_name, avg(cpu_pct) as AVG_CPU
from #CPU
where db_name is not null
group by db_name
order by db_name;

select DB_NAME, snap_time, MAX(cpu_pct) as MAX_CPU
from #CPU
group by db_name, snap_time
having MAX(cpu_pct) > 0
order by MAX(cpu_pct) desc

select db_name, min(total_io) AS MIN_IO, max(total_io) AS MAX_IO, avg(total_io) AS AVG_IO
from #IOPS
group by db_name
order by db_name;

select snap_time, db_name, reads, writes, total_io
from #IOPS
where total_io = (select max(total_io) from #IOPS);

drop table #CPU;

drop table #IOPS;

*/
