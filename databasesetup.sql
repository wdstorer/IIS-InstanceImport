IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'NJOps')
	CREATE DATABASE [NJOps] 
GO

USE NJOps
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='webapps' and xtype='U')
	CREATE TABLE [dbo].[webapps](
		[appid] [int] IDENTITY(1,1) NOT NULL,
		[server] [varchar](50) NULL,
		[name] [varchar](50) NULL,
		[webroot] [varchar](100) NULL,
		[bindings] [varchar](max) NULL,
		[apppool] [varchar](max) NULL,
		[logdir] [varchar](100) NULL,
		[datechanged] [datetime] NULL,
		[siteid] [int] NULL,
		[state] [varchar](50) NULL
	) ON [PRIMARY]
go


IF EXISTS (SELECT * FROM sysobjects WHERE name='njo_sp_UpdateSite' and xtype='P')
	DROP PROCEDURE [dbo].[njo_sp_UpdateSite]

/****** Object:  StoredProcedure [dbo].[njo_sp_UpdateSite]    Script Date: 05/21/2015 08:04:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[njo_sp_UpdateSite]
	@server VARCHAR(50),
	@name VARCHAR(50),
	@webroot VARCHAR(50),
	@bindings VARCHAR(MAX),
	@apppool VARCHAR(MAX),
	@logdir VARCHAR(250),
	@siteid INT,
	@state VARCHAR(50)
AS
BEGIN

DECLARE @testoutput VARCHAR(200)
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF EXISTS(SELECT TOP 1 appid FROM webapps WHERE server+name+CAST(siteid AS VARCHAR(10)) = @server+@name+CAST(@siteid AS VARCHAR(10)))
	BEGIN
		--print 'match found'
		UPDATE dbo.webapps SET WebRoot=@webroot, Bindings=@bindings, AppPool=@apppool, logdir=@logdir, state=@state, datechanged=GetDate() WHERE server+name+CAST(siteid AS VARCHAR(10)) = @server+@name+CAST(@siteid AS VARCHAR(10))
	END
	ELSE
	BEGIN
		--print 'no match'
		INSERT INTO dbo.webapps(Server,Name,WebRoot,Bindings,AppPool,logdir,state,siteid,datechanged) VALUES(@server,@name,@webroot,@bindings,@apppool,@logdir,@state,@siteid,GetDate())
	END
END
GO
