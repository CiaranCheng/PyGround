DECLARE @tmp TABLE(FBillKey VARCHAR(50) NOT NULL,FTableName VARCHAR(50) NOT NULL,FPrimaryFieldName VARCHAR(50) NOT NULL,FSHBZFieldName VARCHAR(50) NOT NULL)

INSERT INTO @tmp(FBillKey,FTableName,FPrimaryFieldName,FSHBZFieldName)
SELECT 'BZHSTD','XSTD','XSTD_TDLS','XSTD_SHBZ'-- 销售提单
UNION SELECT 'SCDD','SCDD','SCDD_LSBH','SCDD_SHBZ'-- 生产订单
UNION SELECT 'SCDDZX','SCDD','SCDD_LSBH','SCDD_SHBZ'-- 生产订单子项
UNION SELECT 'CGDD','CGDD1','CGDD1_LSBH','CGDD1_SHBZ'-- 采购订单
UNION SELECT 'CGDHD','CGDHD1','CGDHD1_LSBH','CGDHD1_SHBZ'-- 采购到货单
UNION SELECT 'DBTZD','KCTZD1','KCTZD1_LSBH','KCTZD1_SHBZ'-- 调拨通知单
-------------------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX)
SET @sql = ''
SELECT @sql = @sql + 'IF (object_id(''trg_SUF_'+t1.FBillKey+t1.FTableName+'_Update'', ''TR'') IS NOT NULL)
	DROP TRIGGER trg_SUF_'+t1.FBillKey+t1.FTableName+'_Update
'
FROM @tmp t1
EXEC sp_executesql @sql

SET @sql = ''
DECLARE cursor_name CURSOR FORWARD_ONLY LOCAL READ_ONLY FOR --定义游标
    SELECT '
CREATE TRIGGER trg_SUF_'+t1.FBillKey+t1.FTableName+'_Update
ON '+t1.FTableName+'
FOR UPDATE
AS
	INSERT INTO dbo.T_SUFI_TaskBuffer(FBillKey,FPrimaryValue,FDateTime)
	SELECT '''+t1.FBillKey+''','+t1.FPrimaryFieldName+',GETDATE() FROM INSERTED WHERE '+t1.FSHBZFieldName+'=1 OR '+t1.FSHBZFieldName+'=4
	--0:未提交;1:审批通过;2:审批否决;3:正在审批;4:免审;
' 
FROM @tmp t1

OPEN cursor_name --打开游标
FETCH NEXT FROM cursor_name INTO @sql  --抓取下一行游标数据
WHILE @@FETCH_STATUS = 0
    BEGIN
		PRINT @sql
        EXEC sp_executesql @sql
		FETCH NEXT FROM cursor_name INTO @sql
    END
CLOSE cursor_name --关闭游标
DEALLOCATE cursor_name --释放游标


--盘点单
IF (object_id('trg_SUF_KCPDBKCYXZ1_Update', 'TR') IS NOT NULL)
	DROP TRIGGER trg_SUF_KCPDBKCYXZ1_Update
GO
CREATE TRIGGER trg_SUF_KCPDBKCYXZ1_Update  
ON KCYXZ1  
FOR INSERT,UPDATE  
AS  
 INSERT INTO dbo.T_SUFI_TaskBuffer(FBillKey,FPrimaryValue,FDateTime)  
 SELECT 'KCPDB',KCYXZ1_LSBH,GETDATE() FROM INSERTED WHERE KCYXZ1_SHBZ=0  
 --0:未提交;1:审批通过 
 AND KCYXZ1_PJLX ='D' -- D代表盘点单，Y是移库单



 -- 校验路线
IF (object_id('trg_SUF_KCCKD1_Update', 'TR') IS NOT NULL)
	DROP TRIGGER trg_SUF_KCCKD1_Update
GO
CREATE TRIGGER trg_SUF_KCCKD1_Update  
ON KCCKD1  
FOR INSERT,UPDATE  
AS  
 INSERT INTO dbo.T_SUFI_TaskBuffer(FBillKey,FPrimaryValue,FDateTime)  
 SELECT 'SCCKD',KCCKD1_LSBH,GETDATE() FROM INSERTED WHERE KCCKD1_SHBZ=0  
 --0:未提交;1:审批通过 
 AND KCCKD1_PJLX ='O' -- O是生产领料单




