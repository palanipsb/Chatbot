DROP PACKAGE LOCKING_PKG;

CREATE OR REPLACE PACKAGE LOCKING_PKG AS

	FUNCTION isPatientLocked(
		n_SetId IN number,
		c_PatId IN varchar
	) RETURN number;

	PROCEDURE lockPatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	);

	PROCEDURE unlockPatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	);

	FUNCTION isPatientFrozen(
		n_SetId IN number,
		c_PatId IN varchar
	) RETURN number; 

	PROCEDURE freezePatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	);

	PROCEDURE unfreezePatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	);
	
	FUNCTION isFormFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer
	) RETURN number;
	
	PROCEDURE freezeForm(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer
	);
	
	PROCEDURE unfreezeForm(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer
	);
	
	FUNCTION isPageFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	) RETURN number;

	PROCEDURE freezePage(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	);
	
	PROCEDURE unfreezePage(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	);
	
	FUNCTION isModuleFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	) RETURN number;
	
	PROCEDURE freezeModule(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	);

	PROCEDURE unfreezeModule(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	);

	FUNCTION isFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar
	) RETURN BOOLEAN;

	FUNCTION isFrozen(
		c_SetDescr IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar
	) RETURN BOOLEAN;
	
END;
/

DROP PACKAGE SDV_PKG;

CREATE OR REPLACE PACKAGE SDV_PKG AS

	PROCEDURE checkGroup(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar
	);

	FUNCTION isPatientVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar
	) RETURN number;

	FUNCTION wasPatientVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar
	) RETURN number;

	PROCEDURE verifyPatient(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar 
	);

	PROCEDURE unverifyPatient(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar 
	);

	FUNCTION isFormVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer 
	) RETURN number;

	FUNCTION wasFormVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer 
	) RETURN number;
	
	PROCEDURE verifyForm(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer 
	);

	PROCEDURE unverifyForm(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer 
	);

	FUNCTION isPageVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer
	) RETURN number;

	FUNCTION wasPageVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer
	) RETURN number;
	
	PROCEDURE verifyPage(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer
	);

	PROCEDURE unverifyPage(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer
	);

	FUNCTION isModuleVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Module IN varchar
	) RETURN number;

	FUNCTION wasModuleVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Module IN varchar
	) RETURN number;
	
	PROCEDURE verifyModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Module IN varchar
	);

	PROCEDURE unverifyModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Module IN varchar
	);

	FUNCTION isFieldVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number;

	FUNCTION wasFieldVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number;

	PROCEDURE verifyField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE unverifyField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE triggerVerifyField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
	);

	FUNCTION isSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number;

	PROCEDURE setSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE removeSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE triggerSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
	); 

	PROCEDURE setSDVNotRequiredModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	); 

	PROCEDURE removeSDVNotRequiredModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	); 

	PROCEDURE triggerSDVNotRequiredModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	); 

	FUNCTION isSDVErrorField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number;

	PROCEDURE setSDVErrorField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE removeSDVErrorField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE onDataUpdate(
		c_WrkId IN varchar,
		c_PatId IN varchar, 
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);

	PROCEDURE onNewQuery(
		c_WrkId IN varchar,
		c_PatId IN varchar, 
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	);
	
	PROCEDURE acceptPassedRbmPage(
        c_GroupId IN varchar,
        c_WrkId IN varchar,
        c_PatId IN varchar,
        n_Form IN integer, 
        n_Page IN integer
    );
    
   FUNCTION allowSdvForPage(        
        c_PatId IN varchar,
        n_Form IN integer,
        n_Page IN integer,
        c_GroupId in varchar
      
    ) RETURN number;
    
    FUNCTION allowSdvForModule(        
        c_PatId IN varchar,
        n_Form IN integer,
        n_Page IN integer,
        c_Module in varchar,
        c_GroupId in varchar                
    ) RETURN number;
    
    FUNCTION allowSdvForField(        
        c_PatId IN varchar,
        n_Form IN integer,
        n_Page IN integer,       
        c_Field in varchar,
        c_GroupId in varchar                 
    ) RETURN number;
    
    FUNCTION isPageSDVComplete(
        c_GroupId IN varchar,                
        c_PatId IN varchar,
        n_Form IN number,
        n_Page IN number        
     ) RETURN number;
    
    FUNCTION isSampleSDVComplete(
        c_GroupId IN varchar,        
        c_BatchId in varchar
     ) RETURN number;
     
     FUNCTION isPageRequiredSDVComplete(
        c_GroupId IN varchar,                
        c_PatId IN varchar,
        n_Form IN number,
        n_Page IN number        
     ) RETURN number;
     
       FUNCTION isBatchRequiredSDVComplete(
        c_GroupId IN varchar,        
        c_BatchId in varchar
     ) RETURN number;
     
     FUNCTION isFieldSDVComplete(
        c_GroupId IN varchar,                
        c_PatId IN varchar,
        c_Field IN varchar,
        n_Form IN number,
        n_Page IN number,
        n_Counter IN number        
     ) RETURN number;
     
     PROCEDURE fillSDVCritical(
     	c_BatchId IN varchar
     );
     
     PROCEDURE addCriticalLoopField(
      	c_PatId IN VARCHAR, 
      	n_Form IN NUMBER, 
      	n_Page IN NUMBER, 
      	n_Counter IN NUMBER, 
      	c_Field IN VARCHAR
      ) ;
      
      PROCEDURE deleteCriticalLoopField(
      	c_PatId IN VARCHAR, 
      	n_Form IN NUMBER, 
      	n_Page IN NUMBER, 
      	n_Counter IN NUMBER, 
      	c_Field IN VARCHAR
      ); 
            

END;
/

DROP PACKAGE UTILS;

CREATE OR REPLACE PACKAGE UTILS 
AS
	FUNCTION EVAL(c_Expr VARCHAR2) RETURN VARCHAR2;	
	FUNCTION EVALD(c_Expr VARCHAR2) RETURN DATE;	
END UTILS;
/
