DROP PACKAGE BODY LOCKING_PKG;

CREATE OR REPLACE PACKAGE BODY LOCKING_PKG AS

	FUNCTION isPatientLocked(
		n_SetId IN number,
		c_PatId IN varchar
	) RETURN number IS 
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from LOCKING 
		where 
			(SET_ID is NULL or BITAND(SET_ID,n_SetId)=n_SetId) and 
			PAT_ID=c_PatId and FORM is NULL and PAGE is NULL and MODULE is NULL and BITAND(STATUS,2)=2;
		return n_Ret;
	end;
	
	PROCEDURE lockPatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	) IS 
	begin
		if (isPatientLocked(n_SetId, c_PatId)<>0) then
			return;
		end if;
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1))+n_SetId, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,2)=2 and BITAND(SET_ID,n_SetId)=0 and 
			PAT_ID=c_PatId and FORM is NULL and PAGE is NULL and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
				set STATUS=BITAND(STATUS,-3)+2, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM is NULL and PAGE is NULL and MODULE is NULL;
			if SQL%NOTFOUND then
				insert into LOCKING 
					(MODIFIED_BY, SET_ID, PAT_ID, FORM, PAGE, MODULE, STATUS, MODIFIED) 
				values 
					(c_WrkId, n_SetId, c_PatId, NULL, NULL, NULL, 2, SYSDATE);
			end if;
		end if;
	end;

	PROCEDURE unlockPatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	) IS 
	begin
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1)), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,2)=2 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM is NULL and PAGE is NULL and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-3), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM is NULL and PAGE is NULL and MODULE is NULL;
		end if;
		delete from LOCKING 
		where 
			STATUS=0 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM is NULL and PAGE is NULL and MODULE is NULL;
	end;
	
	FUNCTION isPatientFrozen(
		n_SetId IN number,
		c_PatId IN varchar
	) RETURN number IS 
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from LOCKING 
		where 
			(SET_ID is NULL or BITAND(SET_ID,n_SetId)=n_SetId) and PAT_ID=c_PatId and 
			FORM is NULL and PAGE is NULL and MODULE is NULL and BITAND(STATUS,1)=1;
		return n_Ret;
	end;

	PROCEDURE freezePatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	) IS 
	begin
		if (isPatientFrozen(n_SetId, c_PatId)<>0) then
			return;
		end if;
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1))+n_SetId, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=0 and PAT_ID=c_PatId and 
			FORM is NULL and PAGE is NULL and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2)+1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and FORM is NULL and PAGE is NULL and MODULE is NULL;
			if SQL%NOTFOUND then
				insert into LOCKING 
					(MODIFIED_BY, SET_ID, PAT_ID, FORM, PAGE, MODULE, STATUS, MODIFIED) 
				values 
					(c_WrkId, n_SetId, c_PatId, NULL, NULL, NULL, 1, SYSDATE);
			end if;
		end if;
	end;

	PROCEDURE unfreezePatient(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar 
	) IS 
	begin
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1)), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM is NULL and PAGE is NULL and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM is NULL and PAGE is NULL and MODULE is NULL;
		end if;
		delete from LOCKING where 
		STATUS=0 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId 
		and FORM is NULL and PAGE is NULL and MODULE is NULL;
	end;
	
	FUNCTION isFormFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer
	) RETURN number IS 
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from LOCKING 
		where 
			(SET_ID is NULL or BITAND(SET_ID,n_SetId)=n_SetId) and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE is NULL and MODULE is NULL and BITAND(STATUS,1)=1;
		return n_Ret;
	end;
	
	PROCEDURE freezeForm(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer
	) IS 
	begin
		if (isFormFrozen(n_SetId, c_PatId, n_Form)<>0) then
			return;
		end if;
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1))+n_SetId, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=0 and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE is NULL and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2)+1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM=n_Form and PAGE is NULL and MODULE is NULL;
			if SQL%NOTFOUND then
				insert into LOCKING 
					(MODIFIED_BY, SET_ID, PAT_ID, FORM, PAGE, MODULE, STATUS, MODIFIED) 
				values 
					(c_WrkId, n_SetId, c_PatId, n_Form, NULL, NULL, 1, SYSDATE);
			end if;
		end if;
	end;
	
	PROCEDURE unfreezeForm(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer
	) IS 
	begin
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1)), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId 
			and FORM=n_Form and PAGE is NULL and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM=n_Form and PAGE is NULL and MODULE is NULL;
		end if;
		delete from LOCKING 
		where 
			STATUS=0 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE is NULL and MODULE is NULL;
	end;
	
	FUNCTION isPageFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	) RETURN number IS 
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from LOCKING 
		where 
			(SET_ID is NULL or BITAND(SET_ID,n_SetId)=n_SetId) and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE is NULL and BITAND(STATUS,1)=1;
		return n_Ret;
	end;

	PROCEDURE freezePage(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	) IS 
	begin
		if (isPageFrozen(n_SetId, c_PatId, n_Form, n_Page)<>0) then
			return;
		end if;
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1))+n_SetId, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=0 and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
				set STATUS=BITAND(STATUS,-2)+1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM=n_Form and PAGE=n_Page and MODULE is NULL;
			if SQL%NOTFOUND then
				insert into LOCKING 
					(MODIFIED_BY, SET_ID, PAT_ID, FORM, PAGE, MODULE, STATUS, MODIFIED) 
				values 
					(c_WrkId, n_SetId, c_PatId, n_Form, n_Page, NULL, 1, SYSDATE);
			end if;
		end if;
	end;
	
	PROCEDURE unfreezePage(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	) IS 
	begin
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1)), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE is NULL;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM=n_Form and PAGE=n_Page and MODULE is NULL;
		end if;
		delete from LOCKING 
		where 
			STATUS=0 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE is NULL;
	end;
	
	FUNCTION isModuleFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	) RETURN number IS 
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from LOCKING 
		where 
			(SET_ID is NULL or BITAND(SET_ID,n_SetId)=n_SetId) and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE=c_Module and BITAND(STATUS,1)=1;
		return n_Ret;
	end;
	
	PROCEDURE freezeModule(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	) IS 
	begin
		if (isModuleFrozen(n_SetId, c_PatId, n_Form, n_Page, c_Module)<>0) then
			return;
		end if;
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1))+n_SetId, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=0 and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE=c_Module;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2)+1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM=n_Form and PAGE=n_Page and MODULE=c_Module;
			if SQL%NOTFOUND then
				insert into LOCKING 
					(MODIFIED_BY, SET_ID, PAT_ID, FORM, PAGE, MODULE, STATUS, MODIFIED) 
				values 
					(c_WrkId, n_SetId, c_PatId, n_Form, n_Page, c_Module, 1, SYSDATE);
			end if;
		end if;
	end;

	PROCEDURE unfreezeModule(
		c_WrkId IN varchar,
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	) IS 
	begin
		update LOCKING 
		set 
			SET_ID=BITAND(SET_ID,-1*(n_SetId+1)), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
		where 
			BITAND(STATUS,1)=1 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE=c_Module;
		if SQL%NOTFOUND then
			update LOCKING 
			set 
				STATUS=BITAND(STATUS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			where 
				BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
				FORM=n_Form and PAGE=n_Page and MODULE=c_Module;
		end if;
		delete from LOCKING 
		where 
			STATUS=0 and BITAND(SET_ID,n_SetId)=n_SetId and PAT_ID=c_PatId and 
			FORM=n_Form and PAGE=n_Page and MODULE=c_Module;
	end;

	FUNCTION isFrozen(
		n_SetId IN number,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar
	) RETURN BOOLEAN IS 
		c_Module varchar(40) := NULL;
	begin
		if (isPatientLocked(n_SetId, c_PatId)<>0 or 
			isPatientFrozen(n_SetId, c_PatId)<>0 or
			isFormFrozen(n_SetId, c_PatId, n_Form)<>0 or
			isPageFrozen(n_SetId, c_PatId, n_Form, n_Page)<>0) 
		then
			return TRUE;
		else
			begin
				select 
					MODULE into c_Module 
				from FIELD_DESCR 
				where 	
					FORM=n_Form and FIELD=c_Field;
				if (isModuleFrozen(n_SetId, c_PatId, n_Form, n_Page, c_Module)<>0) then
					return TRUE;
				end if;
			exception 
				when NO_DATA_FOUND then
					NULL;
			end;
		end if;
		return FALSE;
	end;

	FUNCTION isFrozen(
		c_SetDescr IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar
	) RETURN BOOLEAN IS 
		n_SetId number := 0;
	begin
		select 
			SET_ID into n_SetId 
		from LOCK_DATASETS 
		where 
			DESCR=c_SetDescr;
		return isFrozen(n_SetId, c_PatId, n_Form, n_Page, c_Field);
	end;
	
END;
/

DROP PACKAGE BODY SDV_PKG;

CREATE OR REPLACE PACKAGE BODY SDV_PKG AS

	PROCEDURE checkGroup(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar
	) IS
		c_GroupId_v varchar2(40) := NULL;
	begin
		if (c_GroupId<>'E_SIG') then
			
			begin
				select 
					GROUP_ID into c_GroupId_v 
				from SDV_GROUP_MEMBERS 
				where 
					WRK_ID=c_WrkId and GROUP_ID=c_GroupId and CAN_VERIFY=1;
			exception
				when NO_DATA_FOUND then
					raise_application_error(-20602, 'Could not update table SDV: unknown group ID '||c_GroupId||' or insufficient privilegy');
			end;
		else
			
			begin
				select 
					'E_SIG' into c_GroupId_v 
				from ADM_ICRF4_IF.WORKERS w, ADM_ICRF4_IF.SITES s
				where 
					w.WRK_ID=c_WrkId and w.SIT_ID=s.SIT_ID and 
					BITAND(w.DISABLED,1)=0 and BITAND(s.DISABLED,1)=0 and s.MWRK_ID is not NULL;
			exception
				when NO_DATA_FOUND then
					raise_application_error(-20301, 'Unknown Center No. Please apply to project manager.');
			end;
		end if;
	end;

	
	FUNCTION isPatientVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar
	) RETURN number IS
		n_maxForm number := 0;
	 	n_Dummy number := 0;
	begin
		select max(form) into n_maxForm from FIELD_DESCR;
		
		for f in 0..n_maxForm loop
			n_Dummy := n_Dummy + isFormVerified(c_GroupId, c_PatId, f); 
		end loop;	
	
		if n_Dummy=(n_maxForm+1) then
			return 1;
		end if;
	
		return 0;
	end;

	
	FUNCTION wasPatientVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar
	) RETURN number IS 
		n_maxForm number := 0;
	 	n_Dummy number := 0;
	begin
		select max(form) into n_maxForm from FIELD_DESCR;
		
		for f in 0..n_maxForm loop
			n_Dummy := n_Dummy + wasFormVerified(c_GroupId, c_PatId, f); 
		end loop;	
	
		if n_Dummy=(n_maxForm+1) then
			return 1;
		end if;
	
		return 0;
	end;
	
	PROCEDURE verifyPatient(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar 
	) IS
		n_maxForm number := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);	
		
		select max(form) into n_maxForm from FIELD_DESCR;
		for f in 0..n_maxForm loop
			verifyForm(c_GroupId,  c_WrkId, c_PatId, f); 
		end loop;
	end;


	PROCEDURE unverifyPatient(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar 
	) IS
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		
        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,32)=0);
	end;


	FUNCTION isFormVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer
	) RETURN number IS 
		n_maxPage number := 0;
	 	n_Dummy number := 0;
	begin
	
		select case when max(d.page) is NULL then 0 else max(d.page) end into n_maxPage 
		from
		    DATA d
		where
		    d.pat_id(+)=c_PatId and 
		    d.form(+)=n_Form;

		for p in 0..n_maxPage loop
			n_Dummy := n_Dummy + isPageVerified(c_GroupId, c_PatId, n_Form, p); 
		end loop;	
	
		if n_Dummy=(n_maxPage+1) then
			return 1;
		end if;
	
		return 0;
	end;

	FUNCTION wasFormVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer
	) RETURN number IS 
		n_maxPage number := 0;
	 	n_Dummy number := 0;
	begin
		select case when max(d.page) is NULL then 0 else max(d.page) end into n_maxPage 
		from
		    DATA d
		where
		    d.pat_id(+)=c_PatId and 
		    d.form(+)=n_Form;

		for p in 0..n_maxPage loop
			n_Dummy := n_Dummy + wasPageVerified(c_GroupId, c_PatId, n_Form, p); 
		end loop;	
	
		if n_Dummy=(n_maxPage+1) then
			return 1;
		end if;
	
		return 0;
	end;
	
	PROCEDURE verifyForm(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer 
	) IS 
		n_maxPage number := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
	
		select case when max(d.page) is NULL then 0 else max(d.page) end into n_maxPage 
		from
		    DATA d
		where
		    d.pat_id(+)=c_PatId and 
		    d.form(+)=n_Form;

		for p in 0..n_maxPage loop
			verifyPage(c_GroupId, c_WrkId, c_PatId, n_Form, p);		
		end loop;
	end;

	PROCEDURE unverifyForm(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer 
	) IS
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		
        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,32)=0);
		
	end;

	FUNCTION isPageVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	) RETURN number IS 
	 	n_Dummy number;
		n_maxCounter number := 0;
	 	n_Ret number := 0;
	begin

		
		select count(*) into n_Dummy from (
			select f.field, s.flags as flags from 
				FIELD_DESCR f,
				SDV s
			where
				s.pat_id(+)=c_PatId and
				s.group_id(+)=c_GroupId and 
				f.form=n_Form and f.form=s.form(+) and 
				s.page(+)=n_Page and 
				f.field=s.field(+) and
				f.loop_name is NULL and
				(f.flags is NULL or BITAND(f.flags,8)=0)
		) where
			flags is NULL or 
			(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32) or
			BITAND(FLAGS,2)=2;

		if n_Dummy>0 then
			return 0;
		end if;


		
		for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and loop_name is not NULL) loop
			
			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and f.loop_name=rec.loop_name;
			
		    for i in 0..n_maxCounter loop
		    
				
				select count(*) into n_Dummy from (
					select f.field, s.flags as flags from 
						FIELD_DESCR f,
						SDV s
					where
						s.pat_id(+)=c_PatId and 
						s.group_id(+)=c_GroupId and 
						f.form=n_Form and f.form=s.form(+) and 
						s.page(+)=n_Page and  
						f.field=s.field(+) and 
						(f.flags is NULL or BITAND(f.flags,8)=0) and
						f.loop_name=rec.loop_name and 
						s.counter(+)=i  
				) where 
					flags is NULL or 
					(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32) or
					BITAND(FLAGS,2)=2;
		    
				if n_Dummy>0 then
					return 0;
				end if;
		    
		    end loop;
			
		end loop;				
		
		if n_Dummy=0 then
			n_Ret := 1;
		end if;

		return n_Ret;

	end;
	
	FUNCTION wasPageVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer
	) RETURN number IS 
	 	n_Dummy number;
		n_maxCounter number := 0;
	 	n_Ret number := 0;
	begin

		
		select count(*) into n_Dummy from (
			select f.field, s.flags as flags from 
				FIELD_DESCR f,
				SDV s
			where
				s.pat_id(+)=c_PatId and 
				s.group_id(+)=c_GroupId and 
				f.form=n_Form and f.form=s.form(+) and 
				s.page(+)=n_Page and 
				f.field=s.field(+) and
				(f.flags is NULL or BITAND(f.flags,8)=0) and
				f.loop_name is NULL
		) where 
			flags is NULL or 
			(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32);

		if n_Dummy>0 then
			return 0;
		end if;


		
		for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and loop_name is not NULL) loop
			
			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and f.loop_name=rec.loop_name;
			
		    for i in 0..n_maxCounter loop
		    
				
				select count(*) into n_Dummy from (
					select f.field, s.flags as flags from 
						FIELD_DESCR f,
						SDV s
					where
						s.pat_id(+)=c_PatId and 
						s.group_id(+)=c_GroupId and 
						f.form=n_Form and f.form=s.form(+) and 
						s.page(+)=n_Page and  
						f.field=s.field(+) and 
						(f.flags is NULL or BITAND(f.flags,8)=0) and
						f.loop_name=rec.loop_name and 
						s.counter(+)=i  
				) where 
					flags is NULL or 
					(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32);
		    
				if n_Dummy>0 then
					return 0;
				end if;
		    
		    end loop;
			
		end loop;				
		
		if n_Dummy=0 then
			n_Ret := 1;
		end if;

		return n_Ret;
	end;
	
	PROCEDURE verifyPage(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer
	) IS 
		n_MaxPage number;
		n_Dummy1 number;
		n_maxCounter number := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		if(allowSdvForPage(c_PatId,n_Form,n_Page, c_GroupId)=0) then
            raise_application_error(-20605, 'Could not verify page for risk based monitoring SDV_GROUP' || c_GroupId||'. Page maybe not in a previous batch or open sample.');
        end if;
		
		for rec in (
			select module, field from FIELD_DESCR where form=n_Form and (flags is NULL or BITAND(flags,8)=0) and loop_name is NULL
		) loop
	        begin
	            insert into SDV 
	                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
	            values 
	                (c_GroupId, c_PatId, n_Form, n_Page, rec.module, rec.field, 0, 1, c_WrkId, SYSDATE);
	        exception 
	        when OTHERS then
	            update SDV 
	            set 
	                FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
	            where 
	                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
	                ((rec.module is NULL and MODULE is NULL) or MODULE=rec.module) and 
	                FIELD=rec.field and COUNTER=0
	                and BITAND(FLAGS,32)=0;
	        end;
		end loop;


		
		for rec in (select distinct module, loop_name from FIELD_DESCR where form=n_Form and loop_name is not NULL) loop

			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter 
			from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and
			    ((rec.module is NULL and f.MODULE is NULL) or f.MODULE=rec.module) and
			    f.loop_name=rec.loop_name;

			for i in 0..n_maxCounter loop
			
				for rec2 in (
					select field from FIELD_DESCR where form=n_Form and 
						((rec.module is NULL and MODULE is NULL) or MODULE=rec.module) and
						(flags is NULL or BITAND(flags,8)=0) and	
						loop_name=rec.loop_name
				) loop
			        begin
			            insert into SDV 
			                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
			            values 
			                (c_GroupId, c_PatId, n_Form, n_Page, rec.module, rec2.field, i, 1, c_WrkId, SYSDATE);
			        exception 
			        when OTHERS then
			            update SDV 
			            set 
			                FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			            where 
			                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
			                ((rec.module is NULL and MODULE is NULL) or MODULE=rec.module) and 
			                FIELD=rec2.field and COUNTER=i
			                and BITAND(FLAGS,32)=0;
			        end;
				end loop;
			
			end loop;

		end loop;
		
	end;

	PROCEDURE unverifyPage(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer 
	) IS
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		 IF(allowSdvForPage(c_PatId,n_Form,n_Page, c_GroupId)=0) THEN
            raise_application_error(-20605, 'Could not update page SDV status for risk based monitoring SDV_GROUP' || c_GroupId||'. Page maybe not in a previous batch or open sample.');
        END IF;
		
        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and PAGE=n_Page and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,32)=0);
		
	end;

	FUNCTION isModuleVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	) RETURN number IS
		c_ValidModule VARCHAR2(40) := NULL;
	 	n_Dummy number;
		n_maxCounter number := 0;
	 	n_Ret number := 0;
	begin
	
		if (c_Module is NULL) then
			return 0;
		end if;
	
		begin
			select 
				distinct MODULE into c_ValidModule 
			from FIELD_DESCR 
			where 
				FORM=n_Form and MODULE=c_Module;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not check SDV: unknown module '||c_Module);
		end;
	
		
		select count(*) into n_Dummy from (
			select f.field, s.flags as flags from 
				FIELD_DESCR f,
				SDV s
			where
				s.pat_id(+)=c_PatId and 
				s.group_id(+)=c_GroupId and 
				f.form=n_Form and f.form=s.form(+) and 
				s.page(+)=n_Page and 
				f.field=s.field(+) and
				(f.flags is NULL or BITAND(f.flags,8)=0) and
				f.module=c_Module and f.module=s.module(+) and f.loop_name is NULL
		) where 
			flags is NULL or 
			(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32) or
			BITAND(FLAGS,2)=2;

		if n_Dummy>0 then
			return 0;
		end if;


		
		for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and module=c_Module and loop_name is not NULL) loop
			
			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and f.module=c_Module and f.loop_name=rec.loop_name;
			
		    for i in 0..n_maxCounter loop
		    
				
				select count(*) into n_Dummy from (
					select f.field, s.flags as flags from 
						FIELD_DESCR f,
						SDV s
					where
						s.pat_id(+)=c_PatId and 
						s.group_id(+)=c_GroupId and 
						f.form=n_Form and f.form=s.form(+) and 
						s.page(+)=n_Page and  
						f.field=s.field(+) and
						(f.flags is NULL or BITAND(f.flags,8)=0) and
						f.loop_name=rec.loop_name and 
						s.counter(+)=i and
						f.module=c_Module and f.module=s.module(+) 
				) where 
					flags is NULL or 
					(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32) or
					BITAND(FLAGS,2)=2;
		    
				if n_Dummy>0 then
					return 0;
				end if;
		    
		    end loop;
			
		end loop;				
		
		if n_Dummy=0 then
			n_Ret := 1;
		end if;

		return n_Ret;
	end;
	
	FUNCTION wasModuleVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar
	) RETURN number IS 
		n_Dummy number := 0;
		n_maxCounter number := 0;
		n_Ret number := 0;
	begin
	
		
		select count(*) into n_Dummy from (
			select f.field, s.flags as flags from 
				FIELD_DESCR f,
				SDV s
			where
				s.pat_id(+)=c_PatId and 
				s.group_id(+)=c_GroupId and 
				f.form=n_Form and f.form=s.form(+) and 
				s.page(+)=n_Page and 
				f.field=s.field(+) and
				(f.flags is NULL or BITAND(f.flags,8)=0) and
				f.module=c_Module and f.module=s.module(+) and f.loop_name is NULL
		) where 
			flags is NULL or 
			(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32);

		if n_Dummy>0 then
			return 0;
		end if;

		
		for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and module=c_Module and loop_name is not NULL) loop
			
			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and f.module=c_Module and f.loop_name=rec.loop_name;
			
		    for i in 0..n_maxCounter loop
		    
				
				select count(*) into n_Dummy from (
					select f.field, s.flags as flags from 
						FIELD_DESCR f,
						SDV s
					where
						s.pat_id(+)=c_PatId and 
						s.group_id(+)=c_GroupId and 
						f.form=n_Form and f.form=s.form(+) and 
						s.page(+)=n_Page and  
						f.field=s.field(+) and 
						(f.flags is NULL or BITAND(f.flags,8)=0) and						
						f.loop_name=rec.loop_name and 
						s.counter(+)=i and
						f.module=c_Module and f.module=s.module(+) 
				) where 
					flags is NULL or 
					(BITAND(FLAGS,1)<>1 and BITAND(FLAGS,32)<>32);
		    
				if n_Dummy>0 then
					return 0;
				end if;
		    
		    end loop;
			
		end loop;				
		
		if n_Dummy=0 then
			n_Ret := 1;
		end if;

		return n_Ret;

	end;

	PROCEDURE verifyModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		n_Dummy1 number;
		n_maxCounter number := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		if(allowSdvForModule(c_patId, n_Form, n_Page, c_Module, c_GroupId)=0) then
           raise_application_error(-20606, 'Could not update module SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Module may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE into c_ValidModule 
			from FIELD_DESCR 
			where 
				FORM=n_Form and MODULE=c_Module;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown module '||c_Module);
		end;


		
		for rec in (
			select field from FIELD_DESCR where form=n_Form and (flags is NULL or BITAND(flags,8)=0) and module=c_ValidModule and loop_name is NULL
		) loop
	        begin
	            insert into SDV 
	                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
	            values 
	                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, rec.field, 0, 1, c_WrkId, SYSDATE);
	        exception 
	        when OTHERS then
	            update SDV 
	            set 
	                FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
	            where 
	                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=rec.field and COUNTER=0
	                and BITAND(FLAGS,32)=0;
	        end;
		end loop;


		
		for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and module=c_ValidModule and loop_name is not NULL) loop

			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter 
			from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and f.module=c_ValidModule and f.loop_name=rec.loop_name;

			for i in 0..n_maxCounter loop
			
				for rec2 in (
					select field from FIELD_DESCR where form=n_Form and (flags is NULL or BITAND(flags,8)=0) and module=c_ValidModule and loop_name=rec.loop_name
				) loop
			        begin
			            insert into SDV 
			                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
			            values 
			                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, rec2.field, i, 1, c_WrkId, SYSDATE);
			        exception 
			        when OTHERS then
			            update SDV 
			            set 
			                FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			            where 
			                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=rec2.field and COUNTER=i
			                and BITAND(FLAGS,32)=0;
			        end;
				end loop;
			
			end loop;

		end loop;

	end;

	PROCEDURE unverifyModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		n_Dummy1 number;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		 if(allowSdvForModule(c_patId, n_Form, n_Page, c_Module, c_GroupId)=0) then
           raise_application_error(-20606, 'Could not update module SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Module may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE into c_ValidModule 
			from FIELD_DESCR 
			where 
				FORM=n_Form and MODULE=c_Module;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown module '||c_Module);
		end;


        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_Module;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and PAGE=n_Page and MODULE=c_Module and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,32)=0);
			
	end;

	FUNCTION isFieldVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number IS 
		n_Ret number := 0;
	begin
	
		select 
			count(*) into n_Ret 
		from SDV 
		where 
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
			FORM=n_Form and PAGE=n_Page and FIELD=c_Field and COUNTER=n_Counter and 
			(BITAND(FLAGS,1)=1 or BITAND(FLAGS,32)=32) and BITAND(FLAGS,2)=0;
			
		if n_Ret=0 then
			select 
				count(*) into n_Ret 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field and BITAND(flags,8)=8;
		end if;
			
		return n_Ret;
	end;

	FUNCTION wasFieldVerified(
		c_GroupId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number IS 
		n_Ret number := 0;
	begin
		begin
			select 
				BITAND(FLAGS,1) into n_Ret 
			from SDV 
			where 
				PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
				FORM=n_Form and PAGE=n_Page and FIELD=c_Field and COUNTER=n_Counter;
		exception
		when NO_DATA_FOUND then
			n_Ret:=0;
		end;
		
		if n_Ret=0 then
			select 
				count(*) into n_Ret 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field and BITAND(flags,8)=8;
		end if;
		
		return n_Ret;
	end;

	PROCEDURE verifyField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
		n_Flags NUMBER := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		 if(allowSdvForField(c_PatId, n_Form, n_Page, c_Field, c_GroupId)=0) then
            raise_application_error(-20607, 'Could not update field SDV status for risk based monitoring SDV_GROUP' || c_GroupId||'. Field may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE, FIELD, FLAGS into c_ValidModule, c_ValidField, n_Flags 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown field '||c_Field);
		end;

		
		if (BITAND(n_Flags,8)=8) then
			raise_application_error(-20603, 'SDV not required for field '||c_Field);
		end if;

        begin
            insert into SDV 
                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
            values 
                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, c_ValidField, n_Counter, 1, c_WrkId, SYSDATE);
        exception 
        when OTHERS then
            update SDV 
            set 
                FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
            where 
                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
	            ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
                FIELD=c_ValidField and COUNTER=n_Counter and BITAND(FLAGS,32)=0;
        end;
	        
	end;

	PROCEDURE unverifyField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		 if(allowSdvForField(c_PatId, n_Form, n_Page, c_Field, c_GroupId)=0) then
            raise_application_error(-20607, 'Could not update field SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Field may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE, FIELD into c_ValidModule, c_ValidField 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown field '||c_Field);
		end;

        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-2), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=c_ValidField and COUNTER=n_Counter;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and PAGE=n_Page and 
            ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
			FIELD=c_ValidField and COUNTER=n_Counter and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,32)=0);
	end;


	PROCEDURE triggerVerifyField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
		n_Flags NUMBER := 0;
	begin
	
		begin
			select 
				flags into n_Flags 
			from SDV 
			where 
				PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
				FORM=n_Form and PAGE=n_Page and FIELD=c_Field and COUNTER=n_Counter;
		exception
		when NO_DATA_FOUND then
			n_Flags:=0;
		end;
	
		if (BITAND(n_Flags,32)<>32 and (BITAND(n_Flags,1)<>1 or BITAND(n_Flags,2)=2 or BITAND(n_Flags,16)=16) ) then
			verifyField(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Field, n_Counter);
		else
			unverifyField(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Field, n_Counter);
		end if;
			
	end;


	FUNCTION isSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number IS
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from SDV 
		where 
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
			FORM=n_Form and PAGE=n_Page and FIELD=c_Field and COUNTER=n_Counter and BITAND(FLAGS,32)=32;
		return n_Ret;
	end;

	PROCEDURE setSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
		n_Flags NUMBER := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		  if(allowSdvForField(c_PatId, n_Form, n_Page, c_Field, c_GroupId)=0) then
            raise_application_error(-20607, 'Could not update field SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Field may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE, FIELD, FLAGS into c_ValidModule, c_ValidField, n_Flags 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown field '||c_Field);
		end;

		
		if (BITAND(n_Flags,8)=8) then
			raise_application_error(-20603, 'SDV not required for field '||c_Field);
		end if;

        begin
            insert into SDV 
                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
            values 
                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, c_ValidField, n_Counter, 32, c_WrkId, SYSDATE);
        exception 
        when OTHERS then
            update SDV 
            set 
                FLAGS=32, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
            where 
                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
                ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
                FIELD=c_ValidField and COUNTER=n_Counter;
        end;
	        
	end;

	PROCEDURE removeSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) IS
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		  if(allowSdvForField(c_PatId, n_Form, n_Page, c_Field, c_GroupId)=0) then
            raise_application_error(-20607, 'Could not update field SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Field may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE, FIELD into c_ValidModule, c_ValidField 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown field '||c_Field);
		end;

        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-33), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=c_ValidField and COUNTER=n_Counter;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and PAGE=n_Page and 
            ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
			FIELD=c_ValidField and COUNTER=n_Counter and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,6)=FLAGS);
	end;

	PROCEDURE triggerSDVNotRequiredField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
	begin
		if (1=isSDVNotRequiredField(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Field, n_Counter)) then
			removeSDVNotRequiredField(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Field, n_Counter);
		else
			setSDVNotRequiredField(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Field, n_Counter);
		end if;
	end;

	PROCEDURE setSDVNotRequiredModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		n_Dummy1 number;
		n_maxCounter number := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		  if(allowSdvForModule(c_patId, n_Form, n_Page, c_Module, c_GroupId)=0) then
           raise_application_error(-20606, 'Could not update module SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Module may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE into c_ValidModule 
			from FIELD_DESCR 
			where 
				FORM=n_Form and MODULE=c_Module;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown module '||c_Module);
		end;


		
		for rec in (
			select field from FIELD_DESCR where form=n_Form and (flags is NULL or BITAND(flags,8)=0) and module=c_ValidModule and loop_name is NULL
		) loop
	        begin
	            insert into SDV 
	                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
	            values 
	                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, rec.field, 0, 32, c_WrkId, SYSDATE);
	        exception 
	        when OTHERS then
	            update SDV 
	            set 
	                FLAGS=32, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
	            where 
	                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=rec.field and COUNTER=0
	                and (FLAGS=0 or BITAND(FLAGS,2)=2 or BITAND(FLAGS,4)=4);
	        end;
		end loop;


		
		for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and module=c_ValidModule and loop_name is not NULL) loop

			select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter 
			from
			    FIELD_DESCR f,
			    DATA d
			where
			    d.pat_id(+)=c_PatId and 
			    f.form=n_Form and f.form=d.form(+) and 
			    d.page(+)=n_Page and f.field=d.field(+) and f.module=c_ValidModule and f.loop_name=rec.loop_name;

			for i in 0..n_maxCounter loop
			
				for rec2 in (
					select field from FIELD_DESCR where form=n_Form and (flags is NULL or BITAND(flags,8)=0) and module=c_ValidModule and loop_name=rec.loop_name
				) loop
			        begin
			            insert into SDV 
			                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
			            values 
			                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, rec2.field, i, 32, c_WrkId, SYSDATE);
			        exception 
			        when OTHERS then
			            update SDV 
			            set 
			                FLAGS=32, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
			            where 
			                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=rec2.field and COUNTER=i
			                and (FLAGS=0 or BITAND(FLAGS,2)=2 or BITAND(FLAGS,4)=4);
			        end;
				end loop;
			
			end loop;

		end loop;

	end;

	PROCEDURE removeSDVNotRequiredModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		n_Dummy1 number;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		if(allowSdvForModule(c_patId, n_Form, n_Page, c_Module, c_GroupId)=0) then
           raise_application_error(-20606, 'Could not update module SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Module may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE into c_ValidModule 
			from FIELD_DESCR 
			where 
				FORM=n_Form and MODULE=c_Module;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown module '||c_Module);
		end;

        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-33), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_Module;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and PAGE=n_Page and MODULE=c_Module and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,6)=FLAGS);
			
	end;

	PROCEDURE triggerSDVNotRequiredModule(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer,
		n_Page IN integer,
		c_Module IN varchar 
	) IS 
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
		n_SDVNotReqioredSet number := 0;
	begin
	
		select 
			count(*) into n_SDVNotReqioredSet 
		from SDV 
		where 
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
			FORM=n_Form and PAGE=n_Page and FIELD in (select FIELD from FIELD_DESCR where FORM=n_Form and (flags is NULL or BITAND(flags,8)=0) and MODULE=c_Module) and BITAND(FLAGS,32)=32;
	
		if (n_SDVNotReqioredSet>0) then
			removeSDVNotRequiredModule(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Module);
		else
			setSDVNotRequiredModule(c_GroupId, c_WrkId, c_PatId, n_Form, n_Page, c_Module);
		end if;
	end;

	FUNCTION isSDVErrorField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) RETURN number IS
		n_Ret number := 0;
	begin
		select 
			count(*) into n_Ret 
		from SDV 
		where 
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and 
			FORM=n_Form and PAGE=n_Page and FIELD=c_Field and COUNTER=n_Counter and BITAND(FLAGS,16)=16;
		return n_Ret;
	end;

	PROCEDURE setSDVErrorField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) IS
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
		n_maxCounter number := 0;
		n_IgnoreEmpty number := 0;
		n_DoProcess number := 1;
		n_Fields number := 0;
		n_FieldsTotal number := 0;
		n_FieldsFilled number := 0;
		n_Flags number := 0;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		  if(allowSdvForField(c_PatId, n_Form, n_Page, c_Field, c_GroupId)=0) then
            raise_application_error(-20607, 'Could not update field SDV status for risk based monitoring SDV_GROUP ' || c_GroupId||'. Field may not be in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE, FIELD, FLAGS into c_ValidModule, c_ValidField, n_Flags 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown field '||c_Field);
		end;

		
		if (BITAND(n_Flags,8)=8) then
			raise_application_error(-20603, 'SDV not required for field '||c_Field);
		end if;

		begin
			select
				count(*) into n_IgnoreEmpty 
			from METADATA 
			where 
				NAME='SDV_RATES_EXCLUDE_EMPTY' and (VALUE='1' or VALUE='true');
		exception
			when NO_DATA_FOUND then
				n_IgnoreEmpty := 0;
		end;

		if (n_IgnoreEmpty = 1) then
		
			
			begin
				select count(*) into n_DoProcess from
				    DATA 
				where
				    pat_id=c_PatId and form=n_Form and page=n_Page and field=c_Field and counter=n_Counter and (value is not NULL or spec_value<>0 or comments is not NULL);
			exception
				when NO_DATA_FOUND then
					n_DoProcess := 0;
			end;
		
		end if;

		if (n_DoProcess = 1) then
			
			begin
				select case when 1=count(*) then 0 else 1 end into n_DoProcess from
				    SDV 
				where
	                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
	                ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
	                FIELD=c_ValidField and COUNTER=n_Counter and (BITAND(FLAGS,16)=16 or BITAND(FLAGS,32)=32);
			exception
				when NO_DATA_FOUND then
					n_DoProcess := 0;
			end;
		end if;

		if (n_DoProcess = 1) then

			 
	        begin
	            insert into SDV 
	                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
	            values 
	                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, c_ValidField, n_Counter, 16, c_WrkId, SYSDATE);
	        exception 
	        when OTHERS then
	            update SDV 
	            set 
	                FLAGS=16, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
	            where 
	                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
	                ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
	                FIELD=c_ValidField and COUNTER=n_Counter and BITAND(FLAGS,32)=0;
	        end;


			

			
			begin
				select count(*) into n_FieldsTotal from
				    FIELD_DESCR 
				where
				    form=n_Form and module=c_ValidModule and loop_name is NULL;
			exception
				when NO_DATA_FOUND then
					n_FieldsTotal := 0;
			end;
	
			
			for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and module=c_ValidModule and loop_name is not NULL) loop
	
				
				begin
					select count(*) into n_Fields from
					    FIELD_DESCR 
					where
					    form=n_Form and module=c_ValidModule and loop_name=rec.loop_name;
				exception
					when NO_DATA_FOUND then
						n_Fields := 0;
				end;
	
				
				select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter 
				from
				    FIELD_DESCR f,
				    DATA d
				where
				    d.pat_id(+)=c_PatId and 
				    f.form=n_Form and 
				    d.page(+)=n_Page and 
				    f.form=d.form(+) and 
				    f.field=d.field(+) and 
				    f.module=c_ValidModule and f.loop_name=rec.loop_name;
	
				
				n_FieldsTotal := n_FieldsTotal + (n_Fields * (1+n_maxCounter)); 
	
			end loop;


			

			
			begin
				select count(*) into n_FieldsFilled from
				    FIELD_DESCR f, DATA d  
				where
				    f.form=n_Form and f.module=c_ValidModule and f.loop_name is NULL and
				    f.form=d.form and f.field=d.field and d.pat_id=c_PatId and (d.value is not NULL or d.spec_value<>0);
			exception
				when NO_DATA_FOUND then
					n_FieldsFilled := 0;
			end;
	
			
			for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and module=c_ValidModule and loop_name is not NULL) loop
	
				
				select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter 
				from
				    FIELD_DESCR f,
				    DATA d
				where
				    d.pat_id(+)=c_PatId and 
				    f.form=n_Form and 
				    f.form=d.form(+) and 
				    d.page(+)=n_Page and 
				    f.field=d.field(+) and 
				    f.module=c_ValidModule and f.loop_name=rec.loop_name;
	
				for i in 0..n_maxCounter loop
				
					
					begin
						select count(*) into n_Fields from
						    FIELD_DESCR f, DATA d  
						where
						    f.form=n_Form and f.module=c_ValidModule and f.loop_name=rec.loop_name and
						    f.form=d.form and f.field=d.field and d.counter=i and d.pat_id=c_PatId and (d.value is not NULL or d.spec_value<>0);
					exception
						when NO_DATA_FOUND then
							n_Fields := 0;
					end;
				
				
					
					n_FieldsFilled := n_FieldsFilled + n_Fields; 
				
				end loop;
	
			end loop;


			

	        begin
	            insert into SDV_ERRORS 
	                (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, ERRORS, FIELDS1, FIELDS2, FIELDS3, FIELDS4, MODIFIED, MODIFIED_BY) 
	            values 
	                (c_GroupId, c_PatId, n_Form, n_Page, c_ValidModule, 1, n_FieldsTotal, n_FieldsFilled, n_FieldsTotal, n_FieldsFilled, SYSDATE, c_WrkId);
	        exception 
	        when OTHERS then
	            update SDV_ERRORS 
	            set 
	                ERRORS=ERRORS+1,
	                FIELDS1=n_FieldsTotal, 
	                FIELDS2=n_FieldsFilled, 
	                FIELDS3=GREATEST(FIELDS3, n_FieldsTotal), 
	                FIELDS4=GREATEST(FIELDS4, n_FieldsFilled), 
	                MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
	            where 
	                GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
	                ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule);
	        end;

	    end if;
        
	end;

	PROCEDURE removeSDVErrorField(
		c_GroupId IN varchar,
		c_WrkId IN varchar,
		c_PatId IN varchar,
		n_Form IN integer, 
		n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer
	) IS
		c_ValidModule VARCHAR2(40) := NULL;
		c_ValidField VARCHAR2(40) := NULL;
	begin
		checkGroup(c_GroupId, c_WrkId, c_PatId);
		if(allowSdvForField(c_PatId, n_Form, n_Page, c_Field, c_GroupId)=0) then
            raise_application_error(-20607, 'Could not update field SDV status for risk based monitoring SDV_GROUP' || c_GroupId||'. Field maybe not in a previous batch or open sample.');
        end if;
		
		begin
			select 
				distinct MODULE, FIELD into c_ValidModule, c_ValidField 
			from FIELD_DESCR 
			where 
				FORM=n_Form and FIELD=c_Field;
		exception
			when NO_DATA_FOUND then
				raise_application_error(-20603, 'Could not update table SDV: unknown field '||c_Field);
		end;

        update SDV 
        set 
            FLAGS=BITAND(FLAGS,-17), MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and MODULE=c_ValidModule and FIELD=c_ValidField and COUNTER=n_Counter;

		delete from SDV 
		where 	
			PAT_ID=c_PatId and GROUP_ID=c_GroupId and FORM=n_Form and PAGE=n_Page and 
            ((c_ValidModule is NULL and MODULE is NULL) or MODULE=c_ValidModule) and 
			FIELD=c_ValidField and COUNTER=n_Counter and
			(FLAGS is NULL or FLAGS=0 or BITAND(FLAGS,6)=FLAGS);
	end;

    PROCEDURE onDataUpdate(
        c_WrkId IN varchar,
        c_PatId IN varchar, 
        n_Form IN integer, 
        n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
    ) IS 
        c_Module VARCHAR2(40);
    begin
        
        begin
            select 
                MODULE into c_Module 
            from FIELD_DESCR 
            where 
                FORM=n_Form and FIELD=c_Field;
        exception 
            when NO_DATA_FOUND then
                c_Module:=NULL;
        end;
        
        
	    update SDV 
        set 
        	FLAGS=BITAND(FLAGS,4)+2, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
            ((c_Module is NULL and MODULE is NULL) or MODULE=c_Module) 
            and FIELD=c_Field and COUNTER=n_Counter and BITAND(FLAGS,32)=0;
        
    end;

    PROCEDURE onNewQuery(
        c_WrkId IN varchar,
        c_PatId IN varchar, 
        n_Form IN integer, 
        n_Page IN integer,
		c_Field IN varchar,
		n_Counter IN integer 
    ) IS 
        c_Module VARCHAR2(40);
    begin
        
        begin
            select 
                MODULE into c_Module 
            from FIELD_DESCR 
            where 
                FORM=n_Form and FIELD=c_Field;
        exception 
            when NO_DATA_FOUND then
                c_Module:=NULL;
        end;
    
        
	    update SDV 
        set 
        	FLAGS=BITAND(FLAGS,2)+4, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
        where 
            PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
            ((c_Module is NULL and MODULE is NULL) or MODULE=c_Module) and 
            FIELD=c_Field and COUNTER=n_Counter and BITAND(FLAGS,32)=0;
    
    end;
    


PROCEDURE acceptPassedRbmPage(
        c_GroupId IN varchar,
        c_WrkId IN varchar,
        c_PatId IN varchar,
        n_Form IN integer, 
        n_Page IN integer
    ) IS 
        n_MaxPage number;      
        n_maxCounter number := 0;
    begin
        

        
        for rec in (
            select module, field from FIELD_DESCR where form=n_Form and (flags is NULL or BITAND(flags,24)=0) and loop_name is NULL
        ) loop
            begin
                insert into SDV 
                    (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
                values 
                    (c_GroupId, c_PatId, n_Form, n_Page, rec.module, rec.field, 0, 1, c_WrkId, SYSDATE);
            exception 
            when OTHERS then
                update SDV 
                set 
                    FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
                where 
                    GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
                    ((rec.module is NULL and MODULE is NULL) or MODULE=rec.module) and 
                    FIELD=rec.field and COUNTER=0
                    and BITAND(FLAGS,48)=0;
            end;
        end loop;


        
        for rec in (select distinct module, loop_name from FIELD_DESCR where form=n_Form and loop_name is not NULL) loop

            select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter 
            from
                FIELD_DESCR f,
                DATA d
            where
                d.pat_id(+)=c_PatId and 
                f.form=n_Form and f.form=d.form(+) and 
                d.page(+)=n_Page and f.field=d.field(+) and
                ((rec.module is NULL and f.MODULE is NULL) or f.MODULE=rec.module) and
                f.loop_name=rec.loop_name;

            for i in 0..n_maxCounter loop
            
                for rec2 in (
                    select field from FIELD_DESCR where form=n_Form and 
                        ((rec.module is NULL and MODULE is NULL) or MODULE=rec.module) and
                        (flags is NULL or BITAND(flags,24)=0) and    
                        loop_name=rec.loop_name
                ) loop
                    begin
                        insert into SDV 
                            (GROUP_ID, PAT_ID, FORM, PAGE, MODULE, FIELD, COUNTER, FLAGS, MODIFIED_BY, MODIFIED) 
                        values 
                            (c_GroupId, c_PatId, n_Form, n_Page, rec.module, rec2.field, i, 1, c_WrkId, SYSDATE);
                    exception 
                    when OTHERS then
                        update SDV 
                        set 
                            FLAGS=1, MODIFIED=SYSDATE, MODIFIED_BY=c_WrkId 
                        where 
                            GROUP_ID=c_GroupId and PAT_ID=c_PatId and FORM=n_Form and PAGE=n_Page and 
                            ((rec.module is NULL and MODULE is NULL) or MODULE=rec.module) and 
                            FIELD=rec2.field and COUNTER=i
                            and BITAND(FLAGS,48)=0;
                    end;
                end loop;
            
            end loop;

        end loop;
        
    end;
    
    
   FUNCTION allowSdvForPage(        
        c_PatId IN varchar,
        n_Form IN integer,
        n_Page IN integer,
        c_GroupId in varchar     
      
    ) RETURN number IS
        n_Allow number := 0; 
        c_ConfigGroupId varchar2(40);      
        n_NonCriticals number:=0;
    BEGIN
        
        BEGIN
            select value into c_ConfigGroupId from METADATA where name = 'RBM_SDV_GROUP';
            IF(c_GroupId != c_ConfigGroupId) THEN
                return 1;
            ELSE
                select count(*) into n_NonCriticals from FIELD_DESCR where FORM = n_Form and (BITAND(FLAGS,24)=0 or FLAGS is null);
                IF n_NonCriticals = 0 THEN
                    return 1;
                ELSE                    
                  select case WHEN count(*)>0 THEN 1 ELSE 0 END into n_Allow from SDV_BATCH b join SDV_SESSION s 
                      on B.BATCH_ID = S.BATCH_ID where pat_id = c_PatId and form = n_Form
                      and page = n_Page and ((s.session_accepted = 1 or site_review_by is not null)
                      or(s.session_accepted is null and b.is_sample = 1));
                      
                END IF;
            END IF;       
        EXCEPTION WHEN NO_DATA_FOUND THEN    
            return 1;            
        END;
     
        return n_Allow;
    END;
    
    FUNCTION allowSdvForModule(        
        c_PatId IN varchar,
        n_Form IN integer,
        n_Page IN integer,
        c_Module in varchar,
        c_GroupId in varchar
           
      
    ) RETURN number IS
        n_Allow number := 0; 
        c_ConfigGroupId varchar2(40);      
        n_NonCriticals number:=0;
    BEGIN
        
        BEGIN
            select value into c_ConfigGroupId from METADATA where name = 'RBM_SDV_GROUP';
            IF(c_GroupId != c_ConfigGroupId) THEN
                return 1;
            ELSE
                select count(*) into n_NonCriticals from FIELD_DESCR where FORM = n_Form and MODULE = c_Module and (BITAND(FLAGS,24)=0 or FLAGS is null);
                IF n_NonCriticals = 0 THEN
                    return 1;
                ELSE                    
                  select case WHEN count(*)>0 THEN 1 ELSE 0 END into n_Allow from SDV_BATCH b join SDV_SESSION s 
                      on B.BATCH_ID = S.BATCH_ID where pat_id = c_PatId and form = n_Form
                      and page = n_Page and ((s.session_accepted = 1 or site_review_by is not null)
                      or(s.session_accepted is null and b.is_sample = 1));
                      
                END IF;
            END IF;       
        EXCEPTION WHEN NO_DATA_FOUND THEN    
            return 1;            
        END;
     
        return n_Allow;
    END;
    
    FUNCTION allowSdvForField(        
        c_PatId IN varchar,
        n_Form IN integer,
        n_Page IN integer,       
        c_Field in varchar,
        c_GroupId in varchar
           
      
    ) RETURN number IS
        n_Allow number := 0; 
        c_ConfigGroupId varchar2(40);      
        n_NonCriticals number:=0;
    BEGIN
        
        BEGIN
            select value into c_ConfigGroupId from METADATA where name = 'RBM_SDV_GROUP';
            IF(c_GroupId != c_ConfigGroupId) THEN
                return 1;
            ELSE
                select count(*) into n_NonCriticals from FIELD_DESCR where FORM = n_Form and FIELD = c_Field and (BITAND(FLAGS,16)=0 or FLAGS is null);
                IF n_NonCriticals = 0 THEN
                    return 1;
                ELSE                    
                  select case WHEN count(*)>0 THEN 1 ELSE 0 END into n_Allow from SDV_BATCH b join SDV_SESSION s 
                      on B.BATCH_ID = S.BATCH_ID where pat_id = c_PatId and form = n_Form
                      and page = n_Page and ((s.session_accepted = 1 or site_review_by is not null)
                      or(s.session_accepted is null and b.is_sample = 1));
                      
                END IF;
            END IF;       
        EXCEPTION WHEN NO_DATA_FOUND THEN    
            return 1;            
        END;
     
        return n_Allow;
    END;
    
    
    FUNCTION isPageSDVComplete(
        c_GroupId IN varchar,                
        c_PatId IN varchar,
        n_Form IN number,
        n_Page IN number        
     ) RETURN number IS 
         n_Dummy number;
         n_maxCounter number := 0;
         n_Ret number := 0;    
            
    begin

        

            select count(*) into n_Dummy from (
                select f.field, s.flags as flags from 
                    FIELD_DESCR f,
                    SDV s
                where
                    s.pat_id(+)=c_PatId and
                    s.group_id(+)=c_GroupId and 
                    f.form=n_Form and f.form=s.form(+) and 
                    s.page(+)=n_Page and 
                    f.field=s.field(+) and
                    f.loop_name is NULL and
                    (f.flags is NULL or BITAND(f.flags,8)=0)
            ) where
                flags is NULL or 
                (BITAND(FLAGS,1)<>1 and BITAND(FLAGS,16)<>16 and BITAND(FLAGS,32)<>32); 
                
                    
            if n_Dummy>0 then
                return 0;
            end if;
    
        


        
      
            for rec in (select distinct loop_name from FIELD_DESCR where form=n_Form and loop_name is not NULL) loop
                
                select case when max(d.counter) is NULL then 0 else max(d.counter) end into n_maxCounter from
                    FIELD_DESCR f,
                    DATA d
                where
                    d.pat_id(+)=c_PatId and 
                    f.form=n_Form and f.form=d.form(+) and 
                    d.page(+)=n_Page and f.field=d.field(+) and f.loop_name=rec.loop_name;
                
                for i in 0..n_maxCounter loop
                
                    
                    select count(*) into n_Dummy from (
                        select f.field, s.flags as flags from 
                            FIELD_DESCR f,
                            SDV s
                        where
                            s.pat_id(+)=c_PatId and 
                            s.group_id(+)=c_GroupId and 
                            f.form=n_Form and f.form=s.form(+) and 
                            s.page(+)=n_Page and  
                            f.field=s.field(+) and 
                            (f.flags is NULL or BITAND(f.flags,8)=0) and
                            f.loop_name=rec.loop_name and 
                            s.counter(+)=i  
                    ) where 
                        flags is NULL or 
                (BITAND(FLAGS,1)<>1 and BITAND(FLAGS,16)<>16 and BITAND(FLAGS,32)<>32); 
                
                    if n_Dummy>0 then
                        return 0;
                    end if;
                
                end loop;
                
            end loop;                
            
            if n_Dummy=0 then
                n_Ret := 1;
            end if;
      
        return n_Ret;

    end;
    
     FUNCTION isSampleSDVComplete(
        c_GroupId IN varchar,        
        c_BatchId in varchar
     ) RETURN number IS        
         n_Ret number := 1;       
    begin
       
        for sam in (select pat_id, form, page from SDV_BATCH where BATCH_ID = c_BatchId and is_sample=1) loop
           IF(isPageSDVComplete(c_GroupId,sam.pat_id, sam.form, sam.page)=0) THEN
               return 0;
           END IF;
        end loop;

        return n_Ret;

    end;
    
    FUNCTION isPageRequiredSDVComplete(
        c_GroupId IN varchar,                
        c_PatId IN varchar,
        n_Form IN number,
        n_Page IN number        
     ) RETURN number IS 
         n_Dummy number;                      
            
    begin

        
            select count(*) into n_Dummy from SDV_CRITICAL
            where PAT_ID = c_PatId
            and FORM = n_Form and PAGE=n_Page
            and (PAT_ID, FIELD, FORM, PAGE, COUNTER) NOT IN
            (select PAT_ID, FIELD, FORM, PAGE, COUNTER from SDV where GROUP_ID = c_GroupId and 
            (BITAND(FLAGS, 1) = 1 OR BITAND(FLAGS, 16)=16 OR BITAND(FLAGS, 32) = 32) and PAT_ID =c_PatId and FORM = n_Form and PAGE = n_Page );             
                    
            IF(n_Dummy = 0) THEN
                return 1;
            ELSE 
                return 0;
            END IF;
            

    end;
    
        
    FUNCTION isBatchRequiredSDVComplete(
        c_GroupId IN varchar,        
        c_BatchId in varchar
     ) RETURN number IS        
         n_Ret number := 1;       
    begin
       
        for bat in (select pat_id, form, page from SDV_BATCH where BATCH_ID = c_BatchId) loop
           IF(isPageRequiredSDVComplete(c_GroupId,bat.pat_id, bat.form, bat.page)=0) THEN
               return 0;
           END IF;
        end loop;

        return n_Ret;

    end;
    
     FUNCTION isFieldSDVComplete(
        c_GroupId IN varchar,                
        c_PatId IN varchar,
        c_Field IN varchar,
        n_Form IN number,
        n_Page IN number,
        n_Counter IN number        
     ) RETURN number IS 
         n_Dummy number;
         n_maxCounter number := 0;
         n_Ret number := 0;    
            
    begin

        IF(isFieldVerified(c_GroupId, c_PatId,n_Form, n_Page,c_Field, n_Counter)=1 OR
         isSDVNotRequiredField(c_GroupId, '',c_PatId,n_Form,n_Page, c_Field,n_Counter)=1OR
         isSDVErrorField(c_GroupId, '',c_PatId,n_Form,n_Page, c_Field,n_Counter)=1)THEN
            return 1;
            
        ELSE
            return 0;        
        END IF;

    end;
    
   PROCEDURE fillSDVCritical(c_BatchId IN VARCHAR) IS
     cursor critical_loop is 
         select * from(
        	select d.pat_id, d.form, d.page,f.loop_name,  max(d.counter) as max_counter from DATA d join FIELD_DESCR f on d.form = f.form and d.field = f.field and F.LOOP_NAME is not null join SDV_BATCH b on d.pat_id = b.pat_id and d.form = b.form and d.page = b.page
        	where b.batch_id = c_BatchId and b.is_sample = 0 group by d.pat_id, d.form, d.page, f.loop_name) where max_counter > 0;  
     TYPE LoopFieldCurType IS REF CURSOR;
     loopFieldCursor    LoopFieldCurType;
     c_Field varchar2(24);
     v_stmt_string varchar2(200);
     
     
    BEGIN
       INSERT INTO SDV_CRITICAL select b.pat_Id, f.field, f.form, b.page, 0, c_BatchId, f.LOOP_NAME from SDV_BATCH b join FIELD_DESCR f on b.form = f.form and b.batch_id = c_BatchId where BITAND(f.flags, 16) = 16 and b.is_sample = 0;
       FOR critical in critical_loop LOOP
            v_stmt_string := 'SELECT FIELD FROM FIELD_DESCR where form = :f and loop_name = :l and BITAND(flags, 16)=16';
            
            OPEN loopFieldCursor FOR v_stmt_string USING critical.form, critical.loop_name;
            
            LOOP
                FETCH loopFieldCursor INTO c_Field;
                    EXIT WHEN loopFieldCursor%NOTFOUND;               
                     FOR loopCounter IN 1..critical.max_counter LOOP                                       
                         INSERT INTO SDV_CRITICAL (PAT_ID, FIELD, FORM, PAGE, COUNTER, BATCH_ID, LOOP_NAME) values(critical.pat_id, c_Field, critical.form, critical.page, loopCounter, c_BatchId, critical.loop_name);                                 
                     END LOOP;           
            END LOOP;
            
            CLOSE loopFieldCursor;           
        
       END LOOP;
       
       BEGIN
           INSERT INTO SDV_CRITICAL_LOOPS
            SELECT  distinct d.pat_Id, d.field, d.form, d.page, d.counter, s.loop_name  from 
                DATA d, 
                SDV_CRITICAL s
                where d.pat_id = s.pat_id and 
                d.form = s.form and 
                d.page = s.page and 
                LOOP_NAME IS NOT NULL and 
                BATCH_ID = c_BatchId;
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
            NULL;    
         
        END;     
    END;
    
     PROCEDURE addCriticalLoopField(c_PatId VARCHAR, n_Form NUMBER, n_Page NUMBER, n_Counter NUMBER, c_Field VARCHAR) IS
         c_BatchId VARCHAR2(40);
         c_LoopName VARCHAR2(40);
         c_Query VARCHAR2(200);
         c_LoopField VARCHAR2(40);
         TYPE LoopFieldCurType IS REF CURSOR;
         loopFieldCursor LoopFieldCurType;
     BEGIN            
        select s.BATCH_ID, f.loop_name into c_BatchId, c_LoopName from SDV_SESSION s, SDV_BATCH b, FIELD_DESCR f
        where               
            S.BATCH_ID = B.BATCH_ID and
            s.SESSION_ACCEPTED is null and 
            b.PAT_ID = c_PatId and
            b.FORM = n_Form and 
            b.PAGE = n_Page and
            b.IS_SAMPLE = 0 and 
            f.FIELD = c_Field and
            f.FORM = n_Form;
            IF c_BatchId is not NULL THEN                
                    BEGIN
                    IF c_LoopName IS NOT NULL THEN
                        c_Query := 'SELECT FIELD FROM FIELD_DESCR where form = :f and loop_name = :l and BITAND(flags, 16)=16';            
                        OPEN loopFieldCursor FOR c_Query USING n_Form, c_LoopName;            
                        LOOP
                            FETCH loopFieldCursor INTO c_LoopField;
                                EXIT WHEN loopFieldCursor%NOTFOUND;
                                BEGIN                                                                                                                              
                                    INSERT INTO SDV_CRITICAL (PAT_ID, FIELD, FORM, PAGE, COUNTER, BATCH_ID, LOOP_NAME) values(c_PatId, c_LoopField, n_Form, n_Page, n_Counter, c_BatchId, c_LoopName);
                                EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                                    NULL;
                                END;                                                                                
                        END LOOP;            
                        CLOSE loopFieldCursor;
                        BEGIN
                            INSERT INTO SDV_CRITICAL_LOOPS (PAT_ID, FIELD, FORM,PAGE, COUNTER, LOOP_NAME) 
                                VALUES(c_PatId, c_Field, n_Form, n_Page,n_Counter, c_LoopName);
                        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                            NULL;
                        END;                                                                           
                    END IF;
                END;               
            END IF;
        EXCEPTION WHEN OTHERS THEN    
            c_BatchId := NULL;
                    
        END;
        
        PROCEDURE deleteCriticalLoopField(c_PatId VARCHAR, n_Form NUMBER, n_Page NUMBER, n_Counter NUMBER, c_Field VARCHAR) IS
         c_BatchId VARCHAR2(40);
         c_LoopName VARCHAR2(40);  
         n_DataCount NUMBER :=0;     
         n_IsFieldAvailable NUMBER :=0;    
         n_MaxCounter NUMBER := 0;  
        
         BEGIN                          
            select s.BATCH_ID, f.loop_name into c_BatchId, c_LoopName from SDV_SESSION s, SDV_BATCH b, FIELD_DESCR f
            where               
                S.BATCH_ID = B.BATCH_ID and
                s.SESSION_ACCEPTED is null and 
                b.PAT_ID = c_PatId and
                b.FORM = n_Form and 
                b.PAGE = n_Page and
                b.IS_SAMPLE = 0 and 
                f.FIELD = c_Field and
                f.FORM = n_Form;
                                            
                IF( c_BatchId is not NULL and c_LoopName is not null) THEN                                                                        
                   select count(*) into n_IsFieldAvailable from SDV_CRITICAL_LOOPS
                    where  
                    PAT_ID = c_PatId and
                    FORM = n_Form and
                    PAGE = n_Page and 
                    FIELD = c_Field and
                    COUNTER = n_Counter;
                    
                   IF(n_IsFieldAvailable=1) THEN
                        DELETE FROM SDV_CRITICAL_LOOPS 
                            WHERE  
                            PAT_ID = c_PatId and
                            FORM = n_Form and
                            PAGE = n_Page and
                            FIELD = c_Field and
                            COUNTER = n_Counter;
                            
                         select count(*) into n_DataCount FROM SDV_CRITICAL_LOOPS
                           where
                            PAT_ID = c_PatId and 
                            FORM = n_Form and
                            PAGE = n_Page and 
                            LOOP_NAME = c_LoopName and
                            COUNTER = n_Counter;
                          IF(n_DataCount = 0) THEN
	                            UPDATE SDV_CRITICAL_LOOPS SET COUNTER = COUNTER-1
	                             where 
	                             PAT_ID = c_PatId and
	                             FORM = n_Form and
	                             PAGE = n_Page and
	                             LOOP_NAME = c_LoopName and
	                             COUNTER > n_Counter;
	                             select max(counter) into n_MaxCounter from SDV_CRITICAL_LOOPS
	                                where
	                                PAT_ID = c_PatId and
	                                FORM = n_Form and
	                                PAGE = n_Page and
	                                LOOP_NAME = c_LoopName;
	                             DELETE FROM SDV_CRITICAL WHERE
	                                PAT_ID = c_PatId and
	                                FORM = n_Form and
	                                PAGE = n_Page and
	                                LOOP_NAME = c_LoopName and
	                                COUNTER > n_MaxCounter;
                          END IF;                  
                   END IF;                                                                                                                                        
                END IF;    
            EXCEPTION WHEN OTHERS THEN
            	NULL;            	                               
            END;		
END;
/

DROP PACKAGE BODY UTILS;

CREATE OR REPLACE PACKAGE BODY UTILS
AS

	FUNCTION EVAL(
		c_Expr VARCHAR2
	) RETURN VARCHAR2 IS
		c_Ret varchar2(4000);
	begin
		execute immediate 'begin :result := '||c_Expr||'; end;' using out c_Ret;
		return c_Ret;
	end;	

	FUNCTION EVALD(
		c_Expr VARCHAR2
	) RETURN DATE IS
		d_Ret DATE;
	begin
		execute immediate 'begin :result := '||c_Expr||'; end;' using out d_Ret;
		return d_Ret;
	end;	
	
END UTILS;
/
