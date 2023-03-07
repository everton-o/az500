-- Reference: https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/always-encrypted-tutorial-getting-started?view=sql-server-ver16&tabs=ssms

USE [ContosoHR];
GO

CREATE SCHEMA [HR];
GO

CREATE TABLE [HR].[Employees]
(
    [EmployeeID] [int] IDENTITY(1,1) NOT NULL
    , [SSN] [char](11) NOT NULL
    , [FirstName] [nvarchar](50) NOT NULL
    , [LastName] [nvarchar](50) NOT NULL
    , [Salary] [money] NOT NULL
) ON [PRIMARY];
GO

INSERT INTO [HR].[Employees]
(
    [SSN]
    , [FirstName]
    , [LastName]
    , [Salary]
)
VALUES
(
    '795-73-9838'
    , N'Catherine'
    , N'Abel'
    , $31692
),
(
    '990-00-6818'
    , N'Kim'
    , N'Abercrombie'
    , $55415
);
GO

