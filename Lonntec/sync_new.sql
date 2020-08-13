-----------------------------------------------------------
-- 清理数据
-----------------------------------------------------------

DELETE FROM dbo.T_SUFI_Schema_BaseList WHERE 1=1
DELETE FROM dbo.T_SUFI_Schema_BaseInfo WHERE 1=1
DELETE FROM dbo.T_SUFI_Schema_BillList WHERE 1=1
DELETE FROM dbo.T_SUFI_Schema_BillInfo WHERE 1=1
DELETE FROM dbo.T_SUFI_Schema_BillLinkList WHERE 1=1
DELETE FROM dbo.T_SUFI_Schema_BillLinkInfo WHERE 1=1
DELETE FROM dbo.T_SUFI_Schema_BillLinkSearch WHERE 1=1

-----------------------------------------------------------
-- 常用基础资料
-----------------------------------------------------------
DECLARE @tmpBaseListTable TABLE(FPPItemKey VARCHAR(50) NOT NULL,FBaseType INT NOT NULL,FBaseName VARCHAR(50) NOT NULL,FIsUseCustomView BIT NOT NULL)
-- FIsUseCustomView 0：使用脚本通用视图，将 FIsNumber 列复制一列新列为 ID 列，1：使用自定义脚本
INSERT INTO @tmpBaseListTable(FPPItemKey,FBaseType,FBaseName,FIsUseCustomView)
SELECT 'LSWLZD','101','物料字典',1
UNION SELECT 'JSJLDW','102','计量单位',0
UNION SELECT 'ZWWLDW','109','账务往来单位',0
UNION SELECT 'KCBMZD','110','库存部门字典',1
UNION SELECT 'ZWZGZD','103','账务职工字典',0
UNION SELECT 'LSCKZD','104','仓库字典',0
UNION SELECT 'KCHWZD','105','库存货位字典',1
UNION SELECT 'LSWLLB','999','物料类别',0
UNION SELECT 'ZWDQZD','999','账务地区字典',0
UNION SELECT 'ZWDWLB','999','账务单位类别',0
UNION SELECT 'ZWYGLB','999','账务员工类别',0
UNION SELECT 'JXC_CKYE_SSYE','120','即时库存',1
UNION SELECT 'CFWZ','106','存放位置',1
UNION SELECT 'KCYWLB','999','库存业务类别',0
UNION SELECT 'KCYTZD','999','领用用途',1

-----------------------------------------------------------
-- 业务路线清单
-----------------------------------------------------------

INSERT INTO dbo.T_SUFI_Schema_BillLinkList(FLinkKey,FLinkTitle,FSourceBillKey,FDestBillKey,FIsRed,FCommitType,FUpdateTime)
SELECT 'CGDD->CGRKD','采购订单->采购入库单','CGDD','CGRKD','0','1',GETDATE()
UNION SELECT '0->CGRKD','采购入库单','0','CGRKD','0','1',GETDATE()
UNION SELECT 'SCDDZX->SCCKD','生产订单子项->生产领料单','SCDDZX','SCCKD','0','1',GETDATE()
UNION SELECT '0->SCCKD','生产领料单','0','SCCKD','0','1',GETDATE()
UNION SELECT 'SCDD->SCRKD','生产订单->生产入库单','SCDD','SCRKD','0','1',GETDATE()
UNION SELECT '0->SCRKD','生产入库单','0','SCRKD','0','1',GETDATE()
UNION SELECT 'BZHSTD->XSCKD','销售提单->销售出库单','BZHSTD','XSCKD','0','1',GETDATE()
UNION SELECT '0->XSCKD','销售出库单','0','XSCKD','0','1',GETDATE()
UNION SELECT '->3','库存盘点单','','KCPDB','0','2',GETDATE()

UNION SELECT 'CGDHD->CGRKD','采购到货单->采购入库单','CGDHD','CGRKD','0','1',GETDATE()
UNION SELECT '0->QTRKD','其他入库单','0','QTRKD','0','1',GETDATE()
UNION SELECT '0->PYRKD','盘盈入库单','0','PYRKD','0','1',GETDATE()
-- UNION SELECT 'SCDD->SCCKD','生产订单->生产领料单','SCDD','SCCKD','0','1',GETDATE()
UNION SELECT '0->QTCKD','其他出库单','0','QTCKD','0','1',GETDATE()
UNION SELECT '0->PKCKD','盘亏出库单','0','PKCKD','0','1',GETDATE()
UNION SELECT '0->KCYKD','调拨移库单','0','KCYKD','0','1',GETDATE()

UNION SELECT 'SCDDZX->DBTZD','生产订单->调拨通知单','SCDDZX','DBTZD','0','1',GETDATE()
UNION SELECT 'DBTZD->KCYKD','调拨通知单->调拨移库单','DBTZD','KCYKD','0','1',GETDATE()
-----------------------------------------------------------
-- 业务对象清单（根据 T_SUFI_Schema_BillLinkList 的 FSourceBillKey 和 FDestBillKey 创建）
-----------------------------------------------------------

INSERT INTO dbo.T_SUFI_Schema_BillList(FBillKey,FBillType,FBillName,FExtProps,FUpdateTime)
SELECT table1.FBillKey,
	CASE
	WHEN CHARINDEX('入库',table1.FTitle)>0 THEN 2 -- 入库
	WHEN CHARINDEX('出库',table1.FTitle)>0 THEN 3 -- 出库
	WHEN CHARINDEX('领料',table1.FTitle)>0 THEN 3 -- 出库
	WHEN table1.FTitle='库存盘点单' THEN 4 -- 盘点
	WHEN table1.FTitle='调拨移库单' THEN 5 -- 调拨移库单
	ELSE 1 -- 计划
	END
	,table1.FTitle,NULL,NULL
FROM(
	SELECT t1.FSourceBillKey AS FBillKey,LEFT(t1.FLinkTitle,CASE CHARINDEX('->',t1.FLinkTitle) WHEN 0 THEN 0 ELSE CHARINDEX('->',t1.FLinkTitle)-1 END) AS FTitle
	FROM dbo.T_SUFI_Schema_BillLinkList t1
	UNION
	SELECT t1.FDestBillKey AS FBillKey,RIGHT(t1.FLinkTitle,CASE CHARINDEX('->',t1.FLinkTitle) WHEN 0 THEN LEN(t1.FLinkTitle) ELSE LEN(t1.FLinkTitle)-CHARINDEX('->',t1.FLinkTitle)-1 END) AS FTitle
	FROM dbo.T_SUFI_Schema_BillLinkList t1
) table1
WHERE table1.FBillKey<>'0' AND table1.FBillKey<>''

-----------------------------------------------------------
-- 业务路线清单，校验路线
-----------------------------------------------------------
INSERT INTO dbo.T_SUFI_Schema_BillLinkList(FLinkKey,FLinkTitle,FSourceBillKey,FDestBillKey,FIsRed,FCommitType,FUpdateTime)
SELECT '->SCCKD','生产领料单(校验)','0','SCCKD','0','2',GETDATE()

-----------------------------------------------------------
-- 业务对象信息（根据 T_SUFI_Schema_BillList 创建）
-----------------------------------------------------------
-- @tmpBillListTable 描述 FBillKey 的表头表体在 PPITEM 中的 Key
DECLARE @tmpBillListTable TABLE(FBillKey VARCHAR(50) NOT NULL,FHeadPPItemKey VARCHAR(50) NOT NULL,FEntryPPItemKey VARCHAR(50) NOT NULL)
INSERT INTO @tmpBillListTable
SELECT FBillKey,
CASE FBillKey
WHEN 'SCDD' THEN t_conf.F_SCDD
WHEN 'SCDDZX' THEN t_conf.F_SCDD -- BillKey: 生产订单子项，HeadPPItemKey: 生产订单表头
ELSE FBillKey END, -- 表头
CASE FBillKey
WHEN 'SCDD' THEN t_conf.F_SCDDCP -- BillKey: 生产订单，HeadPPItemKey: 生产订单分录
WHEN 'SCDDZX' THEN t_conf.F_SCDDZX -- BillKey: 生产订单子项，HeadPPItemKey: 生产订单子项
ELSE FBillKey+'2' END -- 表体
FROM dbo.T_SUFI_Schema_BillList,
(SELECT F_VAL,
CASE F_VAL
WHEN 'V11.1' THEN 'SCPTDDFZ'
WHEN 'V12.0' THEN 'WOPTDD' 
ELSE 'SCPTDDFZ' END F_SCDD, -- 生产订单
CASE F_VAL
WHEN 'V11.1' THEN 'SCDDCPZX'
WHEN 'V12.0' THEN 'SCDDCP' 
ELSE 'SCDDCPZX' END F_SCDDCP, -- 生产订单成品
CASE F_VAL
WHEN 'V11.1' THEN 'SCDD2'
WHEN 'V12.0' THEN 'SCDDZX' 
ELSE 'SCDD2' END  F_SCDDZX -- 生产订单子项
FROM LSCONF WHERE F_VKEY = 'CW_VERSION') t_conf


INSERT INTO dbo.T_SUFI_Schema_BillInfo(FBillKey,FPage,FTableName,FFieldName,FFieldTitle,FIndex,FFieldType,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsMustInput,FIsCommit)
SELECT t2.FBillKey,'1',LEFT(t1.PPITEM_DM,CHARINDEX('_',t1.PPITEM_DM)-1),t1.PPITEM_DM,t1.PPITEM_MC,t1.PPITEM_XH,0,dbo.F_SUF_DataType(t1.PPITEM_DM,t1.PPITEM_ZDLX),CASE WHEN LEN(t1.PPITEM_GLXXX)>2 THEN LEFT(t1.PPITEM_GLXXX,LEN(t1.PPITEM_GLXXX)-2) ELSE '' END,'','','','0','1'
FROM PPITEM t1
INNER JOIN @tmpBillListTable t2 ON t1.PPITEM_XXJDM=t2.FHeadPPItemKey -- 表头
UNION
SELECT t2.FBillKey,'1.1',LEFT(t1.PPITEM_DM,CHARINDEX('_',t1.PPITEM_DM)-1),t1.PPITEM_DM,t1.PPITEM_MC,t1.PPITEM_XH,0,dbo.F_SUF_DataType(t1.PPITEM_DM,t1.PPITEM_ZDLX),CASE WHEN LEN(t1.PPITEM_GLXXX)>2 THEN LEFT(t1.PPITEM_GLXXX,LEN(t1.PPITEM_GLXXX)-2) ELSE '' END,'','','','0','1'
FROM PPITEM t1
INNER JOIN @tmpBillListTable t2 ON t1.PPITEM_XXJDM=t2.FEntryPPItemKey -- 表体

UPDATE t1 SET t1.FFieldName='ID',t1.FFieldType=201 -- 标识字段（主键），主键字段重命名为ID
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN @tmpBillListTable t2 ON t1.FBillKey=t2.FBillKey
INNER JOIN PPITEM t3 ON t2.FHeadPPItemKey=t3.PPITEM_XXJDM AND t1.FFieldName=t3.PPITEM_DM -- 表头
WHERE t3.PPITEM_ZDLX='NM'--内码

UPDATE t1 SET t1.FFieldName='ID',t1.FFieldType=201 -- 标识字段（主键），主键字段重命名为ID
,t1.FLookupMetaKey=t4.FTableName,t1.FLookupMetaPrimary=t4.FFieldName,t1.FLookupMasterField='ID',t1.FLookupMetaField=t4.FFieldName
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN @tmpBillListTable t2 ON t1.FBillKey=t2.FBillKey
INNER JOIN PPITEM t3 ON t2.FEntryPPItemKey=t3.PPITEM_XXJDM AND t1.FFieldName=t3.PPITEM_DM -- 表体
INNER JOIN dbo.T_SUFI_Schema_BillInfo t4 ON t1.FBillKey=t4.FBillKey AND t4.FPage='1' AND t4.FFieldType=201
WHERE t3.PPITEM_ZDLX='NM'--内码
AND t1.FBillKey<>'SCDD' AND t1.FBillKey<>'SCDDZX'

UPDATE t1 SET t1.FFieldName='EntryID',t1.FFieldType=201 -- 标识字段（主键），分录主键字段重命名为EntryID
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN @tmpBillListTable t2 ON t1.FBillKey=t2.FBillKey
INNER JOIN PPITEM t3 ON t2.FEntryPPItemKey=t3.PPITEM_XXJDM AND t1.FFieldName=t3.PPITEM_DM -- 表体
WHERE t3.PPITEM_ZDLX='FLH'--内码
AND t1.FBillKey<>'SCDD'

-- Begin 特殊主键处理
UPDATE t1 SET t1.FFieldName='ID',t1.FFieldType=201 -- 标识字段（主键），主键字段重命名为ID
,t1.FLookupMetaKey=t4.FTableName,t1.FLookupMetaPrimary=t4.FFieldName,t1.FLookupMasterField='ID',t1.FLookupMetaField=t4.FFieldName
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN dbo.T_SUFI_Schema_BillInfo t4 ON t1.FBillKey=t4.FBillKey AND t4.FPage='1' AND t4.FFieldType=201
WHERE t1.FBillKey='SCDD' AND t1.FPage='1.1' AND t1.FFieldName='SCDDCP_SCDDLSBH'

UPDATE t1 SET t1.FFieldName='EntryID',t1.FFieldType=201 -- 标识字段（主键），分录主键字段重命名为EntryID
FROM dbo.T_SUFI_Schema_BillInfo t1
WHERE t1.FBillKey='SCDD' AND t1.FPage='1.1' AND t1.FFieldName='SCDDCP_LSBH'

UPDATE dbo.T_SUFI_Schema_BillInfo SET FTableName='SCDDCPMX' WHERE FBillKey='SCDD' AND FPage='1.1'
-- End 特殊主键处理

-----------------------------------------------------------
-- BillInfo FFieldType 处理
-----------------------------------------------------------

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=101/*物料*/
WHERE FFieldName LIKE '%\_WLBH' ESCAPE '\'/*物料*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=104/*仓库*/
WHERE FFieldName LIKE '%\_CKBH' ESCAPE '\'/*仓库*/ OR FFieldName LIKE '%\_YCCK' ESCAPE '\' /*库存盘点单-盘点仓库*/ AND FBillKey <> 'KCYKD' /*调拨移库单只需配置移入仓库*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=104/*仓库*/
WHERE FFieldName LIKE '%\_YRCK' ESCAPE '\' /*库存盘点单-盘点仓库*/ AND FBillKey ='KCYKD' /*调拨移库单只需配置移入仓库*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=105/*仓位*/
WHERE FFieldName LIKE '%\_HWBH' ESCAPE '\'/*货位*/ AND FBillKey <> 'KCYKD' /*调拨移库单只需配置移入货位*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=105/*仓位*/
WHERE FFieldName LIKE '%\_YRHW' ESCAPE '\' AND FBillKey = 'KCYKD' /*调拨移库单只需配置移入货位*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=202/*批次字段*/
WHERE FFieldName LIKE '%\_PCH' ESCAPE '\'/*批次号*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=206/*数量*/
WHERE FFieldName LIKE '%\_SSSL' ESCAPE '\'/*数量*/ AND FBillKey IN ('CGDHD','CGRKD','PYRKD','QTRKD','SCRKD')

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=206/*数量*/
WHERE FFieldName LIKE '%\_SL' ESCAPE '\'/*数量*/ AND FBillKey IN ('CGDD','KCYKD','PKCKD','QTCKD','SCCKD','SCDD','SCDDZX','XSCKD','SCDDZX','DBTZD')

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=206/*数量*/
WHERE FFieldName LIKE '%\_YJCCSL' ESCAPE '\'/*数量*/ AND FBillKey IN ('SCDD')

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=206/*数量*/
WHERE FFieldName LIKE '%\_RKSL' ESCAPE '\'/*数量*/ AND FBillKey IN ('KCPDB')

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=206/*数量*/
WHERE FFieldName LIKE '%\_ZSL' ESCAPE '\'/*数量*/ AND FBillKey IN ('BZHSTD')

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=210/*单据号*/
WHERE FFieldName LIKE '%\_SJDH' ESCAPE '\'/*实际单号*/

UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=211/*单据日期*/
WHERE (FFieldName LIKE '%\_DJRQ' ESCAPE '\'/*单据日期*/ AND FBillKey<>'BZHSTD')OR  FFieldName LIKE '%\_ZDRQ' ESCAPE '\'/*制单日期*/ OR  FFieldName LIKE '%\_YWRQ' ESCAPE '\'/*业务日期*/

-----------------------------------------------------------
-- BillInfo 补入缺失的 Lookup 信息
-----------------------------------------------------------

DECLARE @tmpUpdateBillInfoLookupTable TABLE(FBillKey VARCHAR(50) NOT NULL,FFieldName VARCHAR(50) NOT NULL,FLookupMetaKey VARCHAR(50) NOT NULL)

INSERT INTO @tmpUpdateBillInfoLookupTable(FBillKey,FFieldName,FLookupMetaKey)
-- 销售提单
SELECT 'BZHSTD','XSTD_SHDKH','ZWWLDW' -- 售达客户编号,账务往来单位
UNION SELECT 'BZHSTD','XSTD_SODKH','ZWWLDW' -- 送达客户编号,账务往来单位
UNION SELECT 'BZHSTD','XSTD_SPKH','ZWWLDW' -- 收票客户编号,账务往来单位
UNION SELECT 'BZHSTD','XSTD_FKKH','ZWWLDW' -- 付款客户编号,账务往来单位
UNION SELECT 'BZHSTD','XSTDMX_HWBH','KCHWZD' -- 货位编号,库存货位字典
-- 销售出库单
UNION SELECT 'XSCKD','KCCKD1_DWBH','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'XSCKD','KCCKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'XSCKD','KCCKD1_YTBH','KCYTZD' -- 用途类别，领用用途
UNION SELECT 'XSCKD','KCCKD1_FZR','ZWZGZD' -- 负责人，账务职工字典
UNION SELECT 'XSCKD','KCCKD1_BGY','ZWZGZD' -- 保管员，账务职工字典
UNION SELECT 'XSCKD','KCCKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
-- 生产订单
UNION SELECT 'SCDD','SCDDCP_WLBH','LSWLZD' -- 产品编号,物料字典
UNION SELECT 'SCDD','SCDDCP_JLDW','JSJLDW' -- 计量单位,计量单位
UNION SELECT 'SCDD','SCDDCP_BGR','ZWZGZD' -- 变更人,账务职工字典
-- 生产订单子项
UNION SELECT 'SCDDZX','SCDDZX_WLBH','LSWLZD' -- 产品编号,物料字典
UNION SELECT 'SCDDZX','SCDDZX_JLDW','JSJLDW' -- 计量单位,计量单位
-- 生产入库单
UNION SELECT 'SCRKD','KCRKD1_BGY','ZWZGZD' -- 保管员,账务职工字典
UNION SELECT 'SCRKD','KCRKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'SCRKD','KCRKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
-- 采购订单
UNION SELECT 'CGDD','CGDD1_DDJSF','ZWWLDW' -- 定单接收方编号,账务往来单位
UNION SELECT 'CGDD','CGDD1_HWTGF','ZWWLDW' -- 货物提供方编号,账务往来单位
UNION SELECT 'CGDD','CGDD1_JSF','ZWWLDW' -- 接收方编号,账务往来单位
UNION SELECT 'CGDD','CGDD1_KPF','ZWWLDW' -- 开票方编号,账务往来单位
UNION SELECT 'CGDD','CGDD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'CGDD','CGDD1_SKF','ZWWLDW' -- 收款方编号，账务往来单位
UNION SELECT 'CGDD','CGDD1_YLZZS','ZWWLDW' -- 原料制造商编号，账务往来单位
-- UNION SELECT 'CGDD','CGDD2_CKBH','LSCKZD' -- 仓库编号，仓库字典
-- 采购入库单
UNION SELECT 'CGRKD','KCRKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'CGRKD','KCRKD1_DWBH','ZWWLDW' -- 供方单位，账务往来单位
UNION SELECT 'CGRKD','KCRKD1_JKY','ZWZGZD' -- 缴库员，账务职工字典
UNION SELECT 'CGRKD','KCRKD1_FZR','ZWZGZD' -- 负责人，账务职工字典
UNION SELECT 'CGRKD','KCRKD1_BGY','ZWZGZD' -- 保管员，账务职工字典
UNION SELECT 'CGRKD','KCRKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
-- 生产领料单
UNION SELECT 'SCCKD','KCCKD1_DWBH','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'SCCKD','KCCKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'SCCKD','KCCKD1_LYR','ZWZGZD' -- 领用人，账务职工字典
UNION SELECT 'SCCKD','KCCKD1_FZR','ZWZGZD' -- 负责人，账务职工字典
UNION SELECT 'SCCKD','KCCKD1_BGY','ZWZGZD' -- 保管员，账务职工字典
UNION SELECT 'SCCKD','KCCKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
UNION SELECT 'SCCKD','KCCKD1_YTBH','KCYTZD' -- 用途类别，领用用途
-- 库存盘点表
UNION SELECT 'KCPDB','KCYXZ1_CKLBBH','KCYWLB' -- 业务类别编号，库存业务类别
UNION SELECT 'KCPDB','KCYXZ1_YRBM','KCBMZD' -- 移入部门，库存部门字典
UNION SELECT 'KCPDB','KCYXZ1_YRCK','LSCKZD' -- 移入仓库，仓库字典
UNION SELECT 'KCPDB','KCYXZ2_HWBH','KCHWZD' -- 货位编号,库存货位字典
UNION SELECT 'KCPDB','KCYXZ2_YRHW','KCHWZD' -- 移入货位,库存货位字典
--盘亏出库单
UNION SELECT 'PKCKD','KCCKD1_DWBH','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'PKCKD','KCCKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'PKCKD','KCCKD1_FZR','ZWZGZD' -- 负责人，账务职工字典
UNION SELECT 'PKCKD','KCCKD1_BGY','ZWZGZD' -- 保管员，账务职工字典
UNION SELECT 'PKCKD','KCCKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
--盘盈入库单
UNION SELECT 'PYRKD','KCRKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'PYRKD','KCRKD1_DWBH','ZWWLDW' -- 供方单位，账务往来单位
UNION SELECT 'PYRKD','KCRKD1_JKY','ZWZGZD' -- 缴库员，账务职工字典
UNION SELECT 'PYRKD','KCRKD1_FZR','ZWZGZD' -- 负责人，账务职工字典
UNION SELECT 'PYRKD','KCRKD1_BGY','ZWZGZD' -- 保管员，账务职工字典
UNION SELECT 'PYRKD','KCRKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
--其他入库单
UNION SELECT 'QTRKD','KCRKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
UNION SELECT 'QTRKD','KCRKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
--其他出库单
UNION SELECT 'QTCKD','KCCKD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
UNION SELECT 'QTCKD','KCCKD1_LBBH','KCYWLB' -- 业务类别，库存业务类别
UNION SELECT 'QTCKD','KCCKD1_YTBH','KCYTZD' -- 用途类别，领用用途
--采购到货单
UNION SELECT 'CGDHD','CGDHD1_SKF','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'CGDHD','CGDHD1_KPF','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'CGDHD','CGDHD1_YLZZS','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'CGDHD','CGDHD1_ZGBH','ZWZGZD' -- 采购员，账务职工字典
UNION SELECT 'CGDHD','CGDHD2_HWBH','KCHWZD' -- 货位编号,库存货位字典
--调拨移库单
UNION SELECT 'KCYKD','KCYXZ1_LRXM','ZWZGZD' -- 录入员，账务职工字典
UNION SELECT 'KCYKD','KCYXZ1_PZR','ZWZGZD' -- 批准人，账务职工字典
UNION SELECT 'KCYKD','KCYXZ1_RKXM','ZWZGZD' -- 入库记账人，账务职工字典
UNION SELECT 'KCYKD','KCYXZ1_SHXM','ZWZGZD' -- 审核员，账务职工字典
UNION SELECT 'KCYKD','KCYXZ1_YRY','ZWZGZD' -- 移库员，账务职工字典
UNION SELECT 'KCYKD','KCYXZ2_HWBH','KCHWZD' -- 货位编号,库存货位字典
UNION SELECT 'KCYKD','KCYXZ2_YRHW','KCHWZD' -- 移入货位编号,库存货位字典
--调拨通知单
UNION SELECT 'DBTZD','KCTZD1_LRXM','ZWZGZD' -- 录入员，账务职工字典
UNION SELECT 'DBTZD','KCTZD1_RYBH','ZWZGZD' -- 业务员,账务职工字典
UNION SELECT 'DBTZD','KCTZD1_LRXM','ZWZGZD' -- 录入员,账务职工字典
UNION SELECT 'DBTZD','KCTZD1_DWBH','ZWWLDW' -- 客户编号,账务往来单位
UNION SELECT 'DBTZD','KCTZD2_HWBH','KCHWZD' -- 移出货位编号,库存货位字典
UNION SELECT 'DBTZD','KCTZD2_YRHW','KCHWZD' -- 移入货位编号,库存货位字典

UPDATE t1 SET t1.FLookupMetaKey=t2.FLookupMetaKey
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN @tmpUpdateBillInfoLookupTable t2 ON t1.FBillKey=t2.FBillKey AND t1.FFieldName=t2.FFieldName
WHERE 1=1

-- 删除 非字典类型且存在对应的名称的编码字段，Lookup会在后面重新补新的编码名称
DELETE t1
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN @tmpUpdateBillInfoLookupTable t2 ON t1.FBillKey=t2.FBillKey AND t1.FFieldName=t2.FFieldName+'MC'
WHERE 1=1

-----------------------------------------------------------
-- 基础资料清单
-----------------------------------------------------------

-- 插入常用基础资料
INSERT INTO dbo.T_SUFI_Schema_BaseList(FMetaKey,FBaseType,FBaseName,FUpdateTime)
SELECT FPPItemKey,FBaseType,FBaseName,GETDATE()
FROM @tmpBaseListTable

-- 补充 Lookup 用到而没有定义的基础资料
INSERT INTO dbo.T_SUFI_Schema_BaseList(FMetaKey,FBaseType,FBaseName,FUpdateTime)
SELECT table1.FMetaKey,'999',table1.FMetaKey,GETDATE()
FROM(
	SELECT FLookupMetaKey AS FMetaKey FROM dbo.T_SUFI_Schema_BaseInfo WHERE FLookupMetaKey IS NOT NULL AND FLookupMetaKey<>''
	UNION
	SELECT FLookupMetaKey AS FMetaKey FROM dbo.T_SUFI_Schema_BillInfo WHERE FLookupMetaKey IS NOT NULL AND FLookupMetaKey<>'' AND FFieldType<>201 -- 非标识字段（主键）
) table1
WHERE NOT EXISTS (SELECT 1 FROM dbo.T_SUFI_Schema_BaseList WHERE FMetaKey=table1.FMetaKey)

-----------------------------------------------------------
-- 基础资料信息
-----------------------------------------------------------

INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT PPITEM_XXJDM,PPITEM_DM,PPITEM_MC,PPITEM_XH,dbo.F_SUF_DataType(PPITEM_DM,PPITEM_ZDLX),
CASE WHEN LEN(PPITEM_GLXXX)>2 THEN LEFT(PPITEM_GLXXX,LEN(PPITEM_GLXXX)-2) ELSE '' END,'','','',
'0',CASE WHEN PPITEM_ZDLX='ZDBH' AND PPITEM_DM<>'KCHWZD_CKBH' THEN '1' ELSE '0' END,CASE PPITEM_ZDLX WHEN 'ZDMC' THEN '1' ELSE '0' END,'0'
FROM PPITEM
where EXISTS (SELECT 1 FROM dbo.T_SUFI_Schema_BaseList WHERE FMetaKey=PPITEM_XXJDM)

-- BaseInfo 插入主键（v_SUF中构建的列）
INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT t1.FMetaKey,'ID','主键',t1.FIndex,'101','','','',''
,1,0,0,0
FROM dbo.T_SUFI_Schema_BaseInfo t1
WHERE t1.FIsNumber=1

-----------------------------------------------------------
-- 处理 BaseInfo Lookup 数据
-----------------------------------------------------------

-- BaseInfo 插入 Lookup 字段的 Number 和 Name，并补全 Lookup信息
SELECT * INTO #tmpBaseInfoLookup FROM dbo.T_SUFI_Schema_BaseInfo WHERE FLookupMetaKey<>''
-- 更新 Lookup 列的 Id
UPDATE t1 SET t1.FLookupMetaPrimary=t3.FFieldName,t1.FLookupMasterField=t1.FFieldName,t1.FLookupMetaField=t3.FFieldName
--SELECT t1.FMetaKey,t1.FFieldName,t3.FFieldName
FROM dbo.T_SUFI_Schema_BaseInfo t1
INNER JOIN #tmpBaseInfoLookup t2 ON t1.FMetaKey=t2.FMetaKey AND t1.FFieldName=t2.FFieldName
INNER JOIN dbo.T_SUFI_Schema_BaseInfo t3 ON t2.FLookupMetaKey=t3.FMetaKey
WHERE t3.FIsPrimary=1
-- 插入 Lookup 列的 Number
INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT t1.FMetaKey,t1.FFieldName+'Number',t1.FFieldTitle+'编码',t1.FIndex,'101',t1.FLookupMetaKey,t1.FLookupMetaPrimary,t1.FFieldName,t3.FFieldName
,0,0,0,0
FROM dbo.T_SUFI_Schema_BaseInfo t1
INNER JOIN #tmpBaseInfoLookup t2 ON t1.FMetaKey=t2.FMetaKey AND t1.FFieldName=t2.FFieldName
INNER JOIN dbo.T_SUFI_Schema_BaseInfo t3 ON t2.FLookupMetaKey=t3.FMetaKey
WHERE t3.FIsNumber=1
-- 插入 Lookup 列的 Name
INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT t1.FMetaKey,t1.FFieldName+'Name',t1.FFieldTitle+'名称',t1.FIndex,'101',t1.FLookupMetaKey,t1.FLookupMetaPrimary,t1.FFieldName,t3.FFieldName
,0,0,0,0
FROM dbo.T_SUFI_Schema_BaseInfo t1
INNER JOIN #tmpBaseInfoLookup t2 ON t1.FMetaKey=t2.FMetaKey AND t1.FFieldName=t2.FFieldName
INNER JOIN dbo.T_SUFI_Schema_BaseInfo t3 ON t2.FLookupMetaKey=t3.FMetaKey
WHERE t3.FIsName=1

DROP TABLE #tmpBaseInfoLookup

-----------------------------------------------------------
-- 处理 BillInfo Lookup 数据
-----------------------------------------------------------

-- BillInfo 插入 Lookup 字段的 Number 和 Name，并补全 Lookup信息
SELECT * INTO #tmpBillInfoLookup FROM dbo.T_SUFI_Schema_BillInfo WHERE FLookupMetaKey<>'' AND FFieldType<>201 -- 非标识字段（主键）
-- 更新 Lookup 列的 Id
UPDATE t1 SET t1.FLookupMetaPrimary=t3.FFieldName,t1.FLookupMasterField=t1.FFieldName,t1.FLookupMetaField=t3.FFieldName
--SELECT t1.FMetaKey,t1.FFieldName,t3.FFieldName
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN #tmpBillInfoLookup t2 ON t1.FBillKey=t2.FBillKey AND t1.FFieldName=t2.FFieldName
INNER JOIN dbo.T_SUFI_Schema_BaseInfo t3 ON t2.FLookupMetaKey=t3.FMetaKey
WHERE t3.FIsPrimary=1
-- 插入 Lookup 列的 Number
INSERT INTO dbo.T_SUFI_Schema_BillInfo(FBillKey,FPage,FTableName,FFieldName,FFieldTitle,FIndex,FFieldType,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsMustInput,FIsCommit)
SELECT t1.FBillKey,t1.FPage,t1.FTableName,t1.FFieldName+'Number',t1.FFieldTitle+'编码',t1.FIndex,t1.FFieldType,'101',t1.FLookupMetaKey,t1.FLookupMetaPrimary,t1.FFieldName,t3.FFieldName,0,0
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN #tmpBillInfoLookup t2 ON t1.FBillKey=t2.FBillKey AND t1.FFieldName=t2.FFieldName
INNER JOIN dbo.T_SUFI_Schema_BaseInfo t3 ON t2.FLookupMetaKey=t3.FMetaKey
WHERE t3.FIsNumber=1
-- 插入 Lookup 列的 Name
INSERT INTO dbo.T_SUFI_Schema_BillInfo(FBillKey,FPage,FTableName,FFieldName,FFieldTitle,FIndex,FFieldType,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsMustInput,FIsCommit)
SELECT t1.FBillKey,t1.FPage,t1.FTableName,t1.FFieldName+'Name',t1.FFieldTitle+'名称',t1.FIndex,t1.FFieldType,'101',t1.FLookupMetaKey,t1.FLookupMetaPrimary,t1.FFieldName,t3.FFieldName,0,0
FROM dbo.T_SUFI_Schema_BillInfo t1
INNER JOIN #tmpBillInfoLookup t2 ON t1.FBillKey=t2.FBillKey AND t1.FFieldName=t2.FFieldName
INNER JOIN dbo.T_SUFI_Schema_BaseInfo t3 ON t2.FLookupMetaKey=t3.FMetaKey
WHERE t3.FIsName=1

DROP TABLE #tmpBillInfoLookup

-----------------------------------------------------------
-- 处理 BaseInfo 通用视图
-----------------------------------------------------------

-- 删除 v_SUF 视图
DECLARE @sql NVARCHAR(MAX)
SET @sql = ''
SELECT @sql = @sql + 'IF EXISTS(SELECT 1 FROM sysobjects WHERE name = ''v_SUF_' + t1.FMetaKey + ''' AND xtype = ''V'') ' 
+ ' DROP VIEW v_SUF_' + t1.FMetaKey + '
'
FROM dbo.T_SUFI_Schema_BaseList t1
LEFT JOIN @tmpBaseListTable t2 ON t1.FMetaKey=t2.FPPItemKey
WHERE ISNULL(t2.FIsUseCustomView,0)=0

PRINT @sql
EXEC sp_executesql @sql

-- 重建 v_SUF 视图（构建ID列）
DECLARE @createViewSql NVARCHAR(4000)
DECLARE cursor_name CURSOR FORWARD_ONLY LOCAL READ_ONLY FOR --定义游标
    SELECT '
CREATE VIEW v_SUF_' + t1.FMetaKey + '
AS
	SELECT t1.' + t1.FFieldName + ' AS ID,t1.* FROM ' + t1.FMetaKey + ' t1
' 
FROM dbo.T_SUFI_Schema_BaseInfo t1
INNER JOIN dbo.T_SUFI_Schema_BaseList t2 ON t1.FMetaKey=t2.FMetaKey
LEFT JOIN @tmpBaseListTable t3 ON t1.FMetaKey=t3.FPPItemKey
WHERE t1.FIsNumber=1 AND ISNULL(t3.FIsUseCustomView,0)=0

OPEN cursor_name --打开游标
FETCH NEXT FROM cursor_name INTO @createViewSql  --抓取下一行游标数据
WHILE @@FETCH_STATUS = 0
    BEGIN
		PRINT @createViewSql
        EXEC sp_executesql @createViewSql
		FETCH NEXT FROM cursor_name INTO @createViewSql
    END
CLOSE cursor_name --关闭游标
DEALLOCATE cursor_name --释放游标

-----------------------------------------------------------
-- 更新数据 BaseList，BaseInfo 的 FMetaKey 和 FLookupMetaKey，更新 BillInfo 的 FTableName 和 FLookupMetaKey
-----------------------------------------------------------

UPDATE dbo.T_SUFI_Schema_BaseList SET FMetaKey='v_SUF_'+FMetaKey WHERE 1=1
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FMetaKey='v_SUF_'+FMetaKey WHERE 1=1
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FLookupMetaKey='v_SUF_'+FLookupMetaKey WHERE FLookupMetaKey IS NOT NULL AND FLookupMetaKey<>''

UPDATE dbo.T_SUFI_Schema_BillInfo SET FTableName='v_SUF_'+FTableName WHERE 1=1
UPDATE dbo.T_SUFI_Schema_BillInfo SET FLookupMetaKey='v_SUF_'+FLookupMetaKey WHERE FLookupMetaKey IS NOT NULL AND FLookupMetaKey<>''

-----------------------------------------------------------
-- 插入自定义基础资料信息
-- * 自定义视图在 view.sql 生成
-- * FMetaKey 已经转换成 v_SUF 开头
-- * PPITEM 中不存在元数据，或者元数据增补的字段，在这里补
-----------------------------------------------------------

-- 物料字典 v_SUF_LSWLZD
INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT 'v_SUF_LSWLZD','SFQYPCGL','是否启用批次管理',20,'102','','','','',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','SFQYBZQGL','是否启用保质期管理',20,'102','','','','',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','JBJLDW','基本计量单位',500,'101','v_SUF_JSJLDW','ID','JBJLDW','ID',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','JBJLDWNumber','基本计量单位编码',501,'101','v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','JBJLDWName','基本计量单位名称',502,'101','v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','FF_CKBH','仓库编号',5,'101','v_SUF_LSCKZD','ID','FF_CKBH','ID',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','FF_CKBHNumber','仓库编号编码',6,'101','v_SUF_LSCKZD','ID','FF_CKBH','LSCKZD_CKBH',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','FF_CKBHName','仓库编号名称',7,'101','v_SUF_LSCKZD','ID','FF_CKBH','LSCKZD_CKMC',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','FF_HWBH','货位编号',9,'101','v_SUF_KCHWZD','ID','FF_HWBH','ID',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','FF_HWBHNumber','货位编号编码',10,'101','v_SUF_KCHWZD','ID','FF_HWBH','KCHWZD_HWBH',0,0,0,0
UNION SELECT 'v_SUF_LSWLZD','FF_HWBHName','货位编号名称',11,'101','v_SUF_KCHWZD','ID','FF_HWBH','KCHWZD_HWMC',0,0,0,0

-- 即时库存 v_SUF_JXC_CKYE_SSYE
INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT 'v_SUF_JXC_CKYE_SSYE','ID','主键',1,'101','','','','',1,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_WLBH','物料编号',2,'101','v_SUF_LSWLZD','ID','FF_WLBH','ID',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_WLBHNumber','物料编号编码',3,'101','v_SUF_LSWLZD','ID','FF_WLBH','LSWLZD_WLBH',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_WLBHName','物料编号名称',4,'101','v_SUF_LSWLZD','ID','FF_WLBH','LSWLZD_WLMC',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_CKBH','仓库编号',5,'101','v_SUF_LSCKZD','ID','FF_CKBH','ID',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_CKBHNumber','仓库编号编码',6,'101','v_SUF_LSCKZD','ID','FF_CKBH','LSCKZD_CKBH',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_CKBHName','仓库编号名称',7,'101','v_SUF_LSCKZD','ID','FF_CKBH','LSCKZD_CKMC',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_PCH','批次号',8,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_HWBH','货位编号',9,'101','v_SUF_KCHWZD','ID','FF_HWBH','ID',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_HWBHNumber','货位编号编码',10,'101','v_SUF_KCHWZD','ID','FF_HWBH','KCHWZD_HWBH',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_HWBHName','货位编号名称',11,'101','v_SUF_KCHWZD','ID','FF_HWBH','KCHWZD_HWMC',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_WLZT','物料状态',12,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_WLBZ','物料包装',13,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_TSKC','特殊库存',14,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_XGDX','相关对象',15,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_ZYX1','自由项1',16,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_ZYX2','自由项2',17,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_ZYX3','自由项1',18,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_ZYX4','自由项1',19,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_ZYX5','自由项1',20,'101','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_SLYE','数量余额',21,'105','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_FSLYE1','辅数量余额1',22,'105','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_FSLYE2','辅数量余额2',23,'105','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','FF_JEYE','金额余额',24,'105','','','','',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JLDW','计量单位',25,'101','v_SUF_JSJLDW','ID','JLDW','ID',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JLDWNumber','计量单位编码',26,'101','v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JLDWName','计量单位名称',27,'101','v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JBJLDW','基本计量单位',28,'101','v_SUF_JSJLDW','ID','JBJLDW','ID',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JBJLDWNumber','基本计量单位编码',29,'101','v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JBJLDWName','基本计量单位名称',30,'101','v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','SFQYPCGL','是否启用批次管理',31,'102','v_SUF_LSWLZD','ID','FF_WLBH','SFQYPCGL',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','SFQYBZQGL','是否启用保质期管理',31,'102','v_SUF_LSWLZD','ID','FF_WLBH','SFQYBZQGL',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','GGXH','规格型号',32,'101','v_SUF_LSWLZD','ID','FF_WLBH','LSWLZD_GGXH',0,0,0,0
UNION SELECT 'v_SUF_JXC_CKYE_SSYE','JBDWSL','基本单位数量',33,'105','','','','',0,0,0,0

-- 存放位置 v_SUF_CFWZ
INSERT INTO dbo.T_SUFI_Schema_BaseInfo(FMetaKey,FFieldName,FFieldTitle,FIndex,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsPrimary,FIsNumber,FIsName,FIsOrg)
SELECT 'v_SUF_CFWZ','ID','主键',1,'101','','','','',1,0,0,0
UNION SELECT 'v_SUF_CFWZ','CFWZNumber','编码',2,'101','','','','',0,1,0,0
UNION SELECT 'v_SUF_CFWZ','CFWZName','名称',3,'101','','','','',0,0,1,0
UNION SELECT 'v_SUF_CFWZ','CKID','仓库ID',4,'101','v_SUF_LSCKZD','ID','CKID','ID',0,0,0,0
UNION SELECT 'v_SUF_CFWZ','CKNumber','仓库编码',5,'101','v_SUF_LSCKZD','ID','CKID','LSCKZD_CKBH',0,0,0,0
UNION SELECT 'v_SUF_CFWZ','CKName','仓库名称',6,'101','v_SUF_LSCKZD','ID','CKID','LSCKZD_CKMC',0,0,0,0
UNION SELECT 'v_SUF_CFWZ','HWID','货位ID',7,'101','v_SUF_KCHWZD','ID','HWID','ID',0,0,0,0
UNION SELECT 'v_SUF_CFWZ','HWNumber','货位编码',8,'101','v_SUF_KCHWZD','ID','HWID','KCHWZD_HWBH',0,0,0,0
UNION SELECT 'v_SUF_CFWZ','HWName','货位名称',9,'101','v_SUF_KCHWZD','ID','HWID','KCHWZD_HWMC',0,0,0,0

-----------------------------------------------------------
-- 插入自定义业务对象信息
-- * 自定义视图在 view.sql 生成
-- * FTableName 已经转换成 v_SUF 开头
-- * PPITEM 中不存在元数据，或者元数据增补的字段，在这里补
-----------------------------------------------------------

INSERT INTO dbo.T_SUFI_Schema_BillInfo(FBillKey,FPage,FTableName,FFieldName,FFieldTitle,FIndex,FFieldType,FDataType,FLookupMetaKey,FLookupMetaPrimary,FLookupMasterField,FLookupMetaField,FIsMustInput,FIsCommit)
-- 销售提货
SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','XSTDMX_WLBH','SFQYPCGL',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','XSTDMX_WLBH','SFQYBZQGL',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','XSTDMX_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'BZHSTD','1.1','v_SUF_XSTDMX','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
-- 销售出库单
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'XSCKD','1.1','v_SUF_KCCKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 生产订单
UNION SELECT 'SCDD','1','v_SUF_SCDD','SCDD_SHBZ','审核标志',900,0,101,'','','','',0,1
UNION SELECT 'SCDD','1','v_SUF_SCDD','SCDD_MRBMBH','生产部门',900,0,101,'v_SUF_KCBMZD','ID','SCDD_MRBMBH','ID',0,1
UNION SELECT 'SCDD','1','v_SUF_SCDD','SCDD_MRBMBHNumber','生产部门编码',900,0,101,'v_SUF_KCBMZD','ID','SCDD_MRBMBH','KCBMZD_BMBH',0,0
UNION SELECT 'SCDD','1','v_SUF_SCDD','SCDD_MRBMBHName','生产部门名称',900,0,101,'v_SUF_KCBMZD','ID','SCDD_MRBMBH','KCBMZD_BMMC',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','SCDDCP_WLBH','SFQYPCGL',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','SCDDCP_WLBH','SFQYBZQGL',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','SCDDCP_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'SCDD','1.1','v_SUF_SCDDCPMX','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
-- 生产订单子项
UNION SELECT 'SCDDZX','1','v_SUF_SCDD','SCDD_SHBZ','审核标志',900,0,101,'','','','',0,1
UNION SELECT 'SCDDZX','1','v_SUF_SCDD','SCDD_MRBMBH','生产部门',900,0,101,'v_SUF_KCBMZD','ID','SCDD_MRBMBH','ID',0,1
UNION SELECT 'SCDDZX','1','v_SUF_SCDD','SCDD_MRBMBHNumber','生产部门编码',900,0,101,'v_SUF_KCBMZD','ID','SCDD_MRBMBH','KCBMZD_BMBH',0,0
UNION SELECT 'SCDDZX','1','v_SUF_SCDD','SCDD_MRBMBHName','生产部门名称',900,0,101,'v_SUF_KCBMZD','ID','SCDD_MRBMBH','KCBMZD_BMMC',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','ID','生产订单分组流水号',1,201,101,'v_SUF_SCDD','ID','ID','ID',0,1	/*生产订单子项表体增加ID字段，为生产订单流水号*/
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','SCDDZX_WLBH','SFQYPCGL',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','SCDDZX_WLBH','SFQYBZQGL',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','SCDDZX_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'SCDDZX','1.1','v_SUF_SCDDZX','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
-- 生产入库单
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'SCRKD','1.1','v_SUF_KCRKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 采购入库单
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'CGRKD','1.1','v_SUF_KCRKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 生产领料单
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'SCCKD','1.1','v_SUF_KCCKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 采购订单
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','CGDD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','CGDD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','CGDD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','CGDD2_CKBHNumber','仓库编号编码',900,104,101,'v_SUF_LSCKZD','ID','CGDD2_CKBH','LSCKZD_CKBH',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','CGDD2_CKBHName','仓库编号名称',900,104,101,'v_SUF_LSCKZD','ID','CGDD2_CKBH','LSCKZD_CKMC',0,0
UNION SELECT 'CGDD','1.1','v_SUF_CGDD2','CGDD2_CKBH','仓库编号',900,104,101,'v_SUF_LSCKZD','ID','CGDD2_CKBH','ID',0,0
-- 库存盘点表
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCYXZ2_WLBH','SFQYPCGL',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCYXZ2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCYXZ2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'KCPDB','1.1','v_SUF_KCYXZ2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 采购到货单
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','CGDHD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','CGDHD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','CGDHD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'CGDHD','1.1','v_SUF_CGDHD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
--其他入库单
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'QTRKD','1.1','v_SUF_KCRKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
--盘盈入库单
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCRKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'PYRKD','1.1','v_SUF_KCRKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 盘亏出库单
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'PKCKD','1.1','v_SUF_KCCKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 其他出库单
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCCKD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'QTCKD','1.1','v_SUF_KCCKD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 调拨移库单
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCYXZ2_WLBH','SFQYPCGL',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','SFQYBZQGL','是否启用保质期管理',900,101,102,'v_SUF_LSWLZD','ID','KCYXZ2_WLBH','SFQYBZQGL',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCYXZ2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'KCYKD','1.1','v_SUF_KCYXZ2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1
-- 调拨通知单
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JBDWSL','基本单位数量',900,205,105,'','','','',1,1
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JLDW','计量单位',900,102,101,'v_SUF_JSJLDW','ID','JLDW','ID',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JLDWNumber','计量单位编码',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWDM',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JLDWName','计量单位名称',900,102,101,'v_SUF_JSJLDW','ID','JLDW','JSJLDW_DWMC',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JBJLDW','基本计量单位',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','ID',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JBJLDWNumber','基本计量单位编码',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWDM',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','JBJLDWName','基本计量单位名称',900,101,101,'v_SUF_JSJLDW','ID','JBJLDW','JSJLDW_DWMC',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','SFQYPCGL','是否启用批次管理',900,101,102,'v_SUF_LSWLZD','ID','KCTZD2_WLBH','SFQYPCGL',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','GGXH','规格型号',900,101,101,'v_SUF_LSWLZD','ID','KCTZD2_WLBH','LSWLZD_GGXH',0,0
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','_id_','源单Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','_entryId_','源单分录Id（用于提交)',900,0,101,'','','','',0,1
UNION SELECT 'DBTZD','1.1','v_SUF_KCTZD2','SCRQ','生产日期（批次的属性）',900,203,103,'','','','',0,1

-----------------------------------------------------------
-- * 更新T_SUFI_Schema_BaseInfo的FTubeKey和FTubeIndex
-----------------------------------------------------------
-- 物料字典
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=3 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='LSWLZD_GGXH'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=4 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='SFQYPCGL'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=6 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='SFQYBZQGL'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=9 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='JBJLDW'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=10 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='JBJLDWNumber'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=11 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='JBJLDWName'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube102',FTubeIndex=0 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='JLDW'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube102',FTubeIndex=1 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='JLDWNumber'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube102',FTubeIndex=2 WHERE FMetaKey = 'v_SUF_LSWLZD' AND FFieldName ='JLDWName'

-- 即时库存
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=3 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='GGXH'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=4 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='SFQYPCGL'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=6 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='SFQYBZQGL'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=9 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JBJLDW'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=10 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JBJLDWNumber'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube101',FTubeIndex=11 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JBJLDWName'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube102',FTubeIndex=0 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JLDW'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube102',FTubeIndex=1 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JLDWNumber'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube102',FTubeIndex=2 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JLDWName'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube206',FTubeIndex=0 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='FF_SLYE'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube205',FTubeIndex=0 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='JBDWSL'
UPDATE dbo.T_SUFI_Schema_BaseInfo SET FTubeKey='tube202',FTubeIndex=0 WHERE FMetaKey = 'v_SUF_JXC_CKYE_SSYE' AND FFieldName ='FF_PCH'

--
-----------------------------------------------------------
-- * 更新T_SUFI_Schema_BillInfo的FTubeKey和FTubeIndex
-----------------------------------------------------------
-- 统一
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=9 WHERE FFieldName ='JBJLDW'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=10 WHERE FFieldName ='JBJLDWNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=11 WHERE FFieldName ='JBJLDWName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube102',FTubeIndex=0 WHERE FFieldName ='JLDW'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube102',FTubeIndex=1 WHERE FFieldName ='JLDWNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube102',FTubeIndex=2 WHERE FFieldName ='JLDWName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=3 WHERE FFieldName ='GGXH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=4 WHERE FFieldName ='SFQYPCGL'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=6 WHERE FFieldName ='SFQYBZQGL'

-- 采购订单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=109,FTubeKey='tube109',FTubeIndex=0 WHERE FBillKey='CGDD' AND FFieldName ='CGDD1_HWTGF'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=109,FTubeKey='tube109',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD1_HWTGFNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=109,FTubeKey='tube109',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD1_HWTGFName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube500',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_DJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube501',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_BBJE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube502',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_JXSL'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube503',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_BBSE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube504',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_HSDJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube505',FTubeIndex=1 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_BBHSJE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube700',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_ZYX1'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube701',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_ZYX2'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube702',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_ZYX3'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube703',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_ZYX4'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube704',FTubeIndex=2 WHERE FBillKey='CGDD' AND FFieldName ='CGDD2_ZYX5'
-- 采购入库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_HWBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=103,FTubeKey='tube103',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD1_ZGBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=103,FTubeKey='tube103',FTubeIndex=1 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD1_ZGBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=103,FTubeKey='tube103',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD1_ZGBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube500',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_DJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube501',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_JE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube502',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_SL'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube503',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_SE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube504',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_HSDJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube505',FTubeIndex=0 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_HSJE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube700',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_ZYX1'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube701',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_ZYX2'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube702',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_ZYX3'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube703',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_ZYX4'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube704',FTubeIndex=2 WHERE FBillKey='CGRKD' AND FFieldName ='KCRKD2_ZYX5'

-- 采购到货单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_HWBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=109,FTubeKey='tube109',FTubeIndex=0 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD1_YLZZS'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=109,FTubeKey='tube109',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD1_YLZZSNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=109,FTubeKey='tube109',FTubeIndex=2 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD1_YLZZSName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=210 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD1_DJBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube500',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_DJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube501',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_BBJE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube502',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_TAXRATE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube503',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_HSDJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube504',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_HSDJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube505',FTubeIndex=1 WHERE FBillKey='CGDHD' AND FFieldName ='CGDHD2_BBHSJE'

-- 销售提单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=210 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTD_TDBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube600',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_BZHSJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube601',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_BHSE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube602',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_WLZT'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube603',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_WLBZ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube604',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_ZYX1'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube605',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_ZYX2'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube606',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_ZYX3'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube607',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_ZYX4'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube608',FTubeIndex=0 WHERE FBillKey='BZHSTD' AND FFieldName ='XSTDMX_ZYX5'
-- 生产订单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='SCDD' AND FFieldName ='SCDDCP_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='SCDD' AND FFieldName ='SCDDCP_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='SCDD' AND FFieldName ='SCDDCP_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=210 WHERE FBillKey='SCDD' AND FFieldName ='SCDD_DDBH'

-- 生产订单子项
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='SCDDZX' AND FFieldName ='SCDDZX_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='SCDDZX' AND FFieldName ='SCDDZX_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='SCDDZX' AND FFieldName ='SCDDZX_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=210 WHERE FBillKey='SCDDZX' AND FFieldName ='SCDD_DDBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=211 WHERE FBillKey='SCDDZX' AND FFieldName ='SCDD_ZDRQ'

-- 生产入库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='SCRKD' AND FFieldName ='KCRKD2_HWBHName'
-- 其他入库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='QTRKD' AND FFieldName ='KCRKD2_HWBHName'

-- 盘盈入库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='PYRKD' AND FFieldName ='KCRKD2_HWBHName'

-- 销售出库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_HWBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=103,FTubeKey='tube103',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_LYR'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=103,FTubeKey='tube103',FTubeIndex=1 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_LYRNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=103,FTubeKey='tube103',FTubeIndex=2 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_LYRName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=108,FTubeKey='tube108',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_DWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=108,FTubeKey='tube108',FTubeIndex=1 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_DWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FFieldType=108,FTubeKey='tube108',FTubeIndex=2 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD1_DWBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube600',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_DJ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube601',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_JE'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube602',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_WLZT'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube603',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_WLBZ'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube604',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_ZYX1'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube605',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_ZYX2'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube606',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_ZYX3'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube607',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_ZYX4'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube608',FTubeIndex=0 WHERE FBillKey='XSCKD' AND FFieldName ='KCCKD2_ZYX5'

-- 生产领料单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='SCCKD' AND FFieldName ='KCCKD2_HWBHName'

-- 其他出库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='QTCKD' AND FFieldName ='KCCKD2_HWBHName'

-- 盘亏出库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='PKCKD' AND FFieldName ='KCCKD2_HWBHName'

-- 盘点单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ1_CKBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ1_CKBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ1_CKBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='KCPDB' AND FFieldName ='KCYXZ2_HWBHName'

-- 调拨移库单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ1_YRCK'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ1_YRCKNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ1_YRCKName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ2_YRHW'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ2_YRHWNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='KCYKD' AND FFieldName ='KCYXZ2_YRHWName'

-- 调拨通知单
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=0 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_WLBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=1 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_WLBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube101',FTubeIndex=2 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_WLBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD1_YCCK'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD1_YCCKNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD1_YCCKName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=0 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD1_YRCK'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=1 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD1_YRCKNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube104',FTubeIndex=2 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD1_YRCKName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_HWBH'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_HWBHNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_HWBHName'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=0 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_YRHW'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=1 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_YRHWNumber'
UPDATE dbo.T_SUFI_Schema_BillInfo SET FTubeKey='tube105',FTubeIndex=2 WHERE FBillKey='DBTZD' AND FFieldName ='KCTZD2_YRHWName'
-----------------------------------------------------------
-- 业务路线信息
-----------------------------------------------------------

-- 销售提单->销售出库单
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'BZHSTD->XSCKD','1','KCCKD1_LYBZ','XSTD_PJLX','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_BMBH','XSTD_BMBH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_BMBHNumber','XSTD_BMBHNumber','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_BMBHName','XSTD_BMBHName','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_LYR','XSTD_RYBH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_LYRNumber','XSTD_RYBHNumber','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_LYRName','XSTD_RYBHName','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_TDLS','ID','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_THDH','XSTD_TDBH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_DWBH','XSTD_SHDKH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_DWBHNumber','XSTD_SHDKHNumber','0','0'
UNION SELECT 'BZHSTD->XSCKD','1','KCCKD1_DWBHName','XSTD_SHDKHName','0','0'
-- 分录
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_HWBH','XSTDMX_HWBH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_WLBH','XSTDMX_WLBH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_WLBHNumber','XSTDMX_WLBHNumber','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_WLBHName','XSTDMX_WLBHName','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','GGXH','GGXH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_PCH','XSTDMX_PCH','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_ZYX1','XSTDMX_ZYX1','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_ZYX2','XSTDMX_ZYX2','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_ZYX3','XSTDMX_ZYX3','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_ZYX4','XSTDMX_ZYX4','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_ZYX5','XSTDMX_ZYX5','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','_id_','ID','0','1'
UNION SELECT 'BZHSTD->XSCKD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_SL','XSTDMX_ZSL','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','JLDW','JLDW','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','JLDWNumber','JLDWNumber','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','JLDWName','JLDWName','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','','JBJLDW','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','','JBJLDWName','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_DJ','XSTDMX_BZHSJ','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_JE','XSTDMX_BHSE','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_WLZT','XSTDMX_WLZT','0','0'
UNION SELECT 'BZHSTD->XSCKD','1.1','KCCKD2_WLBZ','XSTDMX_WLBZ','0','0'

-- 生产订单->生产入库单
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'SCDD->SCRKD','1','KCRKD1_BMBH','SCDD_MRBMBH','0','0'
UNION SELECT 'SCDD->SCRKD','1','KCRKD1_BMBHNumber','SCDD_MRBMBHNumber','0','0'
UNION SELECT 'SCDD->SCRKD','1','KCRKD1_BMBHName','SCDD_MRBMBHName','0','0'

-- 表体
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'SCDD->SCRKD','1.1','KCRKD2_WLBH','SCDDCP_WLBH','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','KCRKD2_WLBHNumber','SCDDCP_WLBHNumber','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','KCRKD2_WLBHName','SCDDCP_WLBHName','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','GGXH','GGXH','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','KCRKD2_PCH','SCDDCP_JHPCH','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','_id_','ID','0','1'
UNION SELECT 'SCDD->SCRKD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'SCDD->SCRKD','1.1','KCRKD2_SSSL','SCDDCP_YJCCSL','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','JLDW','SCDDCP_JLDW','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','JLDWNumber','SCDDCP_JLDWNumber','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','JLDWName','SCDDCP_JLDWName','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','','JBJLDW','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'SCDD->SCRKD','1.1','','JBJLDWName','0','0'

-- 采购订单->采购入库单
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'CGDD->CGRKD','1','KCRKD1_BMBH','CGDD1_BMBH','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_BMBHNumber','CGDD1_BMBHNumber','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_BMBHName','CGDD1_BMBHName','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_ZGBH','CGDD1_ZGBH','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_ZGBHNumber','CGDD1_ZGBHNumber','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_ZGBHName','CGDD1_ZGBHName','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_DWBH','CGDD1_DDJSF','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_DWBHNumber','CGDD1_DDJSFNumber','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_DWBHName','CGDD1_DDJSFName','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_DWGC','CGDD1_DWGC','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C1','CGDD1_C1','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C2','CGDD1_C2','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C3','CGDD1_C3','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C4','CGDD1_C4','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C5','CGDD1_C5','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C6','CGDD1_C6','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C7','CGDD1_C7','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C8','CGDD1_C8','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C9','CGDD1_C9','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_C10','CGDD1_C10','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_U1','CGDD1_U1','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_U2','CGDD1_U2','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_U3','CGDD1_U3','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_U4','CGDD1_U4','0','0'
UNION SELECT 'CGDD->CGRKD','1','KCRKD1_U5','CGDD1_U5','0','0'
--插入业务标识
-- 表体
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'CGDD->CGRKD','1.1','KCRKD2_WLBH','CGDD2_WLBH','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_WLBHNumber','CGDD2_WLBHNumber','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_WLBHName','CGDD2_WLBHName','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_DDLS','CGDD2_DDLS','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_DDFL','CGDD2_DDFL','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_CGDDLS','CGDD2_LSBH','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_CGDDFL','CGDD2_FLH','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_CGDDBH','CGDD1_SJDH','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_JHLS','CGDD2_JHLS','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_JHFL','CGDD2_JHFL','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_SSSL','CGDD2_SL','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_PCH','CGDD2_PCH','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','GGXH','GGXH','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','JLDW','JLDW','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','JLDWNumber','JLDWNumber','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','JLDWName','JLDWName','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','','JBJLDW','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','','JBJLDWName','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','_id_','ID','0','1'
UNION SELECT 'CGDD->CGRKD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_ZYX1','CGDD2_ZYX1','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_ZYX2','CGDD2_ZYX2','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_ZYX3','CGDD2_ZYX3','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_ZYX4','CGDD2_ZYX4','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_ZYX5','CGDD2_ZYX5','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C1','CGDD2_C1','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C2','CGDD2_C2','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C3','CGDD2_C3','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C4','CGDD2_C4','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C5','CGDD2_C5','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C6','CGDD2_C6','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C7','CGDD2_C7','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C8','CGDD2_C8','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C9','CGDD2_C9','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_C10','CGDD2_C10','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_U1','CGDD2_U1','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_U2','CGDD2_U2','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_U3','CGDD2_U3','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_U4','CGDD2_U4','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_U5','CGDD2_U5','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_DJ','CGDD2_DJ','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_JE','CGDD2_BBJE','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_SL','CGDD2_JXSL','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_SE','CGDD2_BBSE','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_HSDJ','CGDD2_HSDJ','0','0'
UNION SELECT 'CGDD->CGRKD','1.1','KCRKD2_HSJE','CGDD2_BBHSJE','0','0'
-- 采购到货单->采购入库单
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'CGDHD->CGRKD','1','KCRKD1_BMBH','CGDHD1_BMBH','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_BMBHNumber','CGDHD1_BMBHNumber','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_BMBHName','CGDHD1_BMBHName','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_ZGBH','CGDHD1_ZGBH','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_ZGBHNumber','CGDHD1_ZGBHNumber','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_ZGBHName','CGDHD1_ZGBHName','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_DWBH','CGDHD1_YLZZS','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_DWBHNumber','CGDHD1_YLZZSNumber','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_DWBHName','CGDHD1_YLZZSName','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_DWGC','CGDHD1_DWGC','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C1','CGDHD1_C1','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C2','CGDHD1_C2','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C3','CGDHD1_C3','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C4','CGDHD1_C4','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C5','CGDHD1_C5','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C6','CGDHD1_C6','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C7','CGDHD1_C7','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C8','CGDHD1_C8','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C9','CGDHD1_C9','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_C10','CGDHD1_C10','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_U1','CGDHD1_U1','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_U2','CGDHD1_U2','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_U3','CGDHD1_U3','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_U4','CGDHD1_U4','0','0'
UNION SELECT 'CGDHD->CGRKD','1','KCRKD1_U5','CGDHD1_U5','0','0'
--表体
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'CGDHD->CGRKD','1.1','KCRKD2_WLBH','CGDHD2_WLBH','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_WLBHNumber','CGDHD2_WLBHNumber','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_WLBHName','CGDHD2_WLBHName','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_DDLS','CGDHD2_DDLS','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_DDFL','CGDHD2_DDFL','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_CGDDLS','CGDHD2_LSBH','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_CGDDFL','CGDHD2_FLH','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_CGDDBH','CGDHD2_SJDH','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_JHLS','CGDHD2_JHLS','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_JHFL','CGDHD2_JHFL','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_SSSL','CGDHD2_SSSL','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_PCH','CGDHD2_PCH','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','GGXH','GGXH','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','JLDW','JLDW','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','JLDWNumber','JLDWNumber','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','JLDWName','JLDWName','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','','JBJLDW','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','','JBJLDWName','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','_id_','ID','0','1'
UNION SELECT 'CGDHD->CGRKD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_ZYX1','CGDHD2_ZYX1','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_ZYX2','CGDHD2_ZYX2','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_ZYX3','CGDHD2_ZYX3','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_ZYX4','CGDHD2_ZYX4','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_ZYX5','CGDHD2_ZYX5','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C1','CGDHD2_C1','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C2','CGDHD2_C2','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C3','CGDHD2_C3','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C4','CGDHD2_C4','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C5','CGDHD2_C5','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C6','CGDHD2_C6','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C7','CGDHD2_C7','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C8','CGDHD2_C8','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C9','CGDHD2_C9','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_C10','CGDHD2_C10','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_U1','CGDHD2_U1','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_U2','CGDHD2_U2','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_U3','CGDHD2_U3','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_U4','CGDHD2_U4','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_U5','CGDHD2_U5','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_DJ','CGDHD2_DJ','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_JE','CGDHD2_BBJE','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_SL','CGDHD2_TAXRATE','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_SE','CGDHD2_HSDJ','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_HSDJ','CGDHD2_HSDJ','0','0'
UNION SELECT 'CGDHD->CGRKD','1.1','KCRKD2_HSJE','CGDHD2_BBHSJE','0','0'

-- 生产订单->生产领料单
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'SCDDZX->SCCKD','1','KCCKD1_BMBH','SCDD_MRBMBH','0','0'
UNION SELECT 'SCDDZX->SCCKD','1','KCCKD1_BMBHNumber','SCDD_MRBMBHNumber','0','0'
UNION SELECT 'SCDDZX->SCCKD','1','KCCKD1_BMBHName','SCDD_MRBMBHName','0','0'
-- 分录
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_WLBH','SCDDZX_WLBH','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_WLBHNumber','SCDDZX_WLBHNumber','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_WLBHName','SCDDZX_WLBHName','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C1','SCDDZX_C1','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C2','SCDDZX_C2','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C3','SCDDZX_C3','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C4','SCDDZX_C4','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C5','SCDDZX_C5','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C6','SCDDZX_C6','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C7','SCDDZX_C7','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C8','SCDDZX_C8','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C9','SCDDZX_C9','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_C10','SCDDZX_C10','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_U1','SCDDZX_U1','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_U2','SCDDZX_U2','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_U3','SCDDZX_U3','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_U4','SCDDZX_U4','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_U5','SCDDZX_U5','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_ZYX1','SCDDZX_ZYX1','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_ZYX2','SCDDZX_ZYX2','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_ZYX3','SCDDZX_ZYX3','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_ZYX4','SCDDZX_ZYX4','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_ZYX5','SCDDZX_ZYX5','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','_id_','ID','0','1'
UNION SELECT 'SCDDZX->SCCKD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'SCDDZX->SCCKD','1.1','KCCKD2_SL','SCDDZX_SL','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','JLDW','SCDDZX_JLDW','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','JLDWNumber','SCDDZX_JLDWNumber','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','JLDWName','SCDDZX_JLDWName','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','','JBJLDW','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'SCDDZX->SCCKD','1.1','','JBJLDWName','0','0'

-- 生产订单->调拨通知
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'SCDDZX->DBTZD','1','KCTZD1_BMBH','SCDD_MRBMBH','0','0'
UNION SELECT 'SCDDZX->DBTZD','1','KCTZD1_BMBHNumber','SCDD_MRBMBHNumber','0','0'
UNION SELECT 'SCDDZX->DBTZD','1','KCTZD1_BMBHName','SCDD_MRBMBHName','0','0'
-- 分录
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_WLBH','SCDDZX_WLBH','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_WLBHNumber','SCDDZX_WLBHNumber','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_WLBHName','SCDDZX_WLBHName','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C1','SCDDZX_C1','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C2','SCDDZX_C2','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C3','SCDDZX_C3','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C4','SCDDZX_C4','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C5','SCDDZX_C5','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C6','SCDDZX_C6','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C7','SCDDZX_C7','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C8','SCDDZX_C8','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C9','SCDDZX_C9','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_C10','SCDDZX_C10','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_U1','SCDDZX_U1','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_U2','SCDDZX_U2','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_U3','SCDDZX_U3','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_U4','SCDDZX_U4','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_U5','SCDDZX_U5','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_ZYX1','SCDDZX_ZYX1','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_ZYX2','SCDDZX_ZYX2','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_ZYX3','SCDDZX_ZYX3','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_ZYX4','SCDDZX_ZYX4','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_ZYX5','SCDDZX_ZYX5','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','_id_','ID','0','1'
UNION SELECT 'SCDDZX->DBTZD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'SCDDZX->DBTZD','1.1','KCTZD2_SL','SCDDZX_SL','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','JLDW','SCDDZX_JLDW','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','JLDWNumber','SCDDZX_JLDWNumber','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','JLDWName','SCDDZX_JLDWName','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','','JBJLDW','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'SCDDZX->DBTZD','1.1','','JBJLDWName','0','0'

-- 调拨通知->调拨移库
-- 表头
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'DBTZD->KCYKD','1','KCYXZ1_BMBH','KCTZD1_BMBH','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_BMBHNumber','KCTZD1_BMBHNumber','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_BMBHName','KCTZD1_BMBHName','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C1','KCTZD1_C1','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C2','KCTZD1_C2','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C3','KCTZD1_C3','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C4','KCTZD1_C4','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C5','KCTZD1_C5','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C6','KCTZD1_C6','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C7','KCTZD1_C7','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C8','KCTZD1_C8','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C9','KCTZD1_C9','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_C10','KCTZD1_C10','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_U1','KCTZD1_U1','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_U2','KCTZD1_U2','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_U3','KCTZD1_U3','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_U4','KCTZD1_U4','0','0'
UNION SELECT 'DBTZD->KCYKD','1','KCYXZ1_U5','KCTZD1_U5','0','0'
-- 分录
INSERT INTO dbo.T_SUFI_Schema_BillLinkInfo(FLinkKey,FDestPage,FDestFieldName,FSrcFieldName,FIsSelectMatch,FIsPrimary)
SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_WLBH','KCTZD2_WLBH','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_WLBHNumber','KCTZD2_WLBHNumber','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_WLBHName','KCTZD2_WLBHName','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C1','KCTZD2_C1','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C2','KCTZD2_C2','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C3','KCTZD2_C3','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C4','KCTZD2_C4','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C5','KCTZD2_C5','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C6','KCTZD2_C6','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C7','KCTZD2_C7','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C8','KCTZD2_C8','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C9','KCTZD2_C9','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_C10','KCTZD2_C10','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_U1','KCTZD2_U1','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_U2','KCTZD2_U2','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_U3','KCTZD2_U3','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_U4','KCTZD2_U4','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_U5','KCTZD2_U5','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_ZYX1','KCTZD2_ZYX1','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_ZYX2','KCTZD2_ZYX2','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_ZYX3','KCTZD2_ZYX3','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_ZYX4','KCTZD2_ZYX4','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_ZYX5','KCTZD2_ZYX5','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_PCH','KCTZD2_PCH','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','GGXH','GGXH','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','_id_','ID','0','1'
UNION SELECT 'DBTZD->KCYKD','1.1','_entryId_','EntryID','0','1'
UNION SELECT 'DBTZD->KCYKD','1.1','KCYXZ2_SL','KCTZD2_SL','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','JBDWSL','JBDWSL','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','JLDW','KCTZD2_JLDW','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','JLDWNumber','KCTZD2_JLDWNumber','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','JLDWName','KCTZD2_JLDWName','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','','JBJLDW','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','','JBJLDWNumber','0','0'
UNION SELECT 'DBTZD->KCYKD','1.1','','JBJLDWName','0','0'

-----------------------------------------------------------
-- 业务路线搜索条件
-----------------------------------------------------------

INSERT INTO dbo.T_SUFI_Schema_BillLinkSearch(FLinkKey,FColName,FFieldTitle,FDataType,FIndex,FIsPrimary)
SELECT 'BZHSTD->XSCKD','ID','主键',101,1,1
UNION SELECT 'BZHSTD->XSCKD','XSTD_TDBH','提单编号',101,2,0
UNION SELECT 'BZHSTD->XSCKD','XSTD_YWRQ','业务日期',103,3,0
UNION SELECT 'BZHSTD->XSCKD','KCCKD1_DWBHName','客户编号名称',101,4,0
UNION SELECT 'SCDD->SCRKD','ID','主键',101,1,1
UNION SELECT 'SCDD->SCRKD','SCDD_DDBH','订单编号',101,2,0
UNION SELECT 'SCDD->SCRKD','SCDD_ZDRQ','制单日期',103,3,0
UNION SELECT 'SCDDZX->SCCKD','ID','主键',101,1,1
UNION SELECT 'SCDDZX->SCCKD','SCDD_DDBH','生产订单编号',101,2,0
UNION SELECT 'SCDDZX->SCCKD','SCDD_ZDRQ','制单日期',103,3,0
UNION SELECT '->3','ID','主键',101,1,1
UNION SELECT '->3','KCYXZ1_SJDH','订单编号',101,2,0
UNION SELECT '->3','KCYXZ1_DJRQ','单据日期',103,3,0
UNION SELECT 'CGDD->CGRKD','ID','主键',101,1,1
UNION SELECT 'CGDD->CGRKD','CGDD1_SJDH','订单编号',101,2,0
UNION SELECT 'CGDD->CGRKD','CGDD1_DJRQ','单据日期',103,3,0
UNION SELECT 'CGDD->CGRKD','CGDD1_HWTGFName','供货单位编号名称',101,4,0
UNION SELECT 'CGDHD->CGRKD','ID','主键',101,1,1
UNION SELECT 'CGDHD->CGRKD','CGDHD1_DJBH','实际单号',101,2,0
UNION SELECT 'CGDHD->CGRKD','CGDHD1_DJRQ','单据日期',103,3,0
UNION SELECT 'CGDHD->CGRKD','CGDHD1_YLZZSName','原料制造商编号名称',101,4,0
UNION SELECT '->SCCKD','ID','主键',101,1,1
UNION SELECT '->SCCKD','KCCKD1_SJDH','单据编号',101,2,0
UNION SELECT '->SCCKD','KCCKD1_DJRQ','单据日期',103,3,0
UNION SELECT 'SCDDZX->DBTZD','ID','主键',101,1,1
UNION SELECT 'SCDDZX->DBTZD','SCDD_DDBH','生产订单编号',101,2,0
UNION SELECT 'SCDDZX->DBTZD','SCDD_ZDRQ','制单日期',103,3,0
UNION SELECT 'DBTZD->KCYKD','ID','主键',101,1,1
UNION SELECT 'DBTZD->KCYKD','KCTZD1_SJDH','调拨通知单编号',101,2,0
UNION SELECT 'DBTZD->KCYKD','KCTZD1_DJRQ','制单日期',103,3,0
-----------------------------------------------------------
-- 字段显示名称与系统一致
-----------------------------------------------------------
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '移出仓库' WHERE  FBillKey = 'KCYKD' AND FFieldName = 'KCYXZ1_YCCKName'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '移出仓库编号' WHERE  FBillKey = 'KCYKD' AND FFieldName = 'KCYXZ1_YCCKNumber'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '移入仓库' WHERE  FBillKey = 'KCYKD' AND FFieldName = 'KCYXZ1_YRCKName'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '移入仓库编号' WHERE  FBillKey = 'KCYKD' AND FFieldName = 'KCYXZ1_YRCKNumber'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '订单类别' WHERE FBillKey = 'CGDD' AND FFieldName = 'CGDD1_LBBHName'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '订单类别编号' WHERE FBillKey = 'CGDD' AND FFieldName = 'CGDD1_LBBHNumber'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '业务类别' WHERE  FFieldName = 'KCRKD1_LBBHName'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '业务类别编号' WHERE  FFieldName = 'KCRKD1_LBBHNumber'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '业务类别' WHERE  FFieldName = 'KCCKD1_LBBHName'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '业务类别编号' WHERE  FFieldName = 'KCCKD1_LBBHNumber'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '业务类别' WHERE  FFieldName = 'KCYXZ1_CKLBBHName'
UPDATE  T_SUFI_Schema_Billinfo SET FFieldTitle = '业务类别编号' WHERE  FFieldName = 'KCYXZ1_CKLBBHNumber'



