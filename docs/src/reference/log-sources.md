# Log Sources for Security Monitoring

Customers can monitor their Snowflake deployment for potential indicators of compromise by integrating Snowflake log sources with their Security Information and Event Monitoring (SIEM) solution. This guide documents the security identifiers and the Information Schema and Account Usage columns that Snowflake recommends customers monitor. In addition, this publication maps columns to the MITRE ATT&CK SaaS Matrix, an industry framework that helps security analysts implement detection and response controls that align to their organization's incident response procedures.

## Security Identifiers and Views
| Security Identifier/View | Columns | Schema Location | Latency | MITRE ATT&CK |
|---|---|---|---|---|
| Applicable_Roles | Grantee<br>Role_Name<br>Role_Owner<br>Is_Grantable | Information Schema | n/a | <a href="https://attack.mitre.org/techniques/T1060/" target="_blank">T1060- Permission Group Discovery</a><br><a href="https://attack.mitre.org/techniques/T1087/" target="_blank">T1087 - Account Discovery</a> |
| Stages | Stage_Name<br>Created<br>Last_Altered | Information Schema | n/a | <a href="https://attack.mitre.org/techniques/T1213/" target="_blank">T1213- Data Collection/ Exfiltration</a><br><a href="https://attack.mitre.org/techniques/T1074/" target="_blank">T1074 Data Staged</a> |
| Usage_Privileges | Grantor<br>Grantee<br>Privilege_Type<br>Is_Grantable<br>Created | Information Schema | n/a | <a href="https://attack.mitre.org/techniques/T1078/" target="_blank">T1078- Privilege Escalation</a> |
| Object_Privileges | Grantor<br>Grantee<br>Privilege_Type<br>Is_Grantable<br>Created | Information Schema | n/a | <a href="https://attack.mitre.org/techniques/T1078/" target="_blank">T1078- Privilege Escalation</a> |
| Access_History | Query_ID<br>Query_Start_Time<br>User_Name<br>Direct_Objects_Accessed<br>Base_Objects_Accesssed | Account_Usage | 3 hours | <a href="https://attack.mitre.org/techniques/T1078/" target="_blank">T1078- Valid Accounts</a> |
| Copy_History | All Applicable Columns | Account_Usage | 2 Hours | <a href="https://attack.mitre.org/techniques/T1213/" target="_blank">T1213- Data Collection</a><br><a href="https://attack.mitre.org/techniques/T1074/" target="_blank">T1074 - Data Staged</a> |
| Data_Transfer_History | Start_Time<br>End_Time<br>Source_Cloud<br>Source_Region<br>Target_Cloud<br>Target_Region | Account_Usage | 2 Hours | <a href="https://attack.mitre.org/techniques/T1213/" target="_blank">T1213- Data Collection</a><br><a href="https://attack.mitre.org/techniques/T1074/" target="_blank">T1074 - Data Staged</a> |
| Grants_To_Roles | Created_On<br>Modified_On<br>Privilege<br>Granted_On<br>Name<br>Granted_To<br>Grantee_Name<br>Grant_Option<br>Granted_By<br>Deleted_On | Account_Usage | 2 Hours | <a href="https://attack.mitre.org/techniques/T1078/" target="_blank">T1078- Privilege Escalation</a> |
| Grants_To_Users | Created_On<br>Deleted_On<br>Role<br>Granted_To<br>Grantee_Name<br>Granted_By | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1078/" target="_blank">T1078- Privilege Escalation</a> |
| Login_History | Event_Timestamp<br>Event_Type<br>User_Name<br>Client_IP<br>Reported_Client_Type<br>First_Authentication_Factor<br>Second_Authentication_Factor<br>Is_Success | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1078/" target="_blank">T1078.004- Cloud Accounts</a> |
| Masking_Policies | Policy_Name<br>Created<br>Last_Altered<br>Deleted | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1080/" target="_blank">T1080- Taint Shared Content</a><br><a href="https://attack.mitre.org/tactics/TA0005/" target="_blank">TA0005 - Defense Evasion</a> |
| Query_History | All Applicable Columns | Account_Usage | 45 minutes | <a href="https://attack.mitre.org/tactics/TA0003/" target="_blank">TA0003 - Persistence</a><br><a href="https://attack.mitre.org/tactics/TA0003/" target="_blank">TA0003 - Valid Accounts</a> |
| Roles | Created_On<br>Deleted_On<br>Name | Account_Usage | 2 hours | <a href="https://attack.mitre.org/tactics/TA0003/" target="_blank">TA0003 - Persistence</a> |
| Row_Access_Policies | Policy_Name<br>Created<br>Last_Altered<br>Deleted | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1080/" target="_blank">T1080- Taint Shared Content</a><br><a href="https://attack.mitre.org/tactics/TA0005/" target="_blank">TA0005 - Defense Evasion</a> |
| Sessions | Session_Id<br>Created_On<br>User_Name<br>Authentication_Method<br>Login_Event_Id<br>Client_Application_Version<br>Client_Application_Id<br>Client_Enviornment<br>Client_Build_Id<br>Client_Version | Account_Usage | 3 hours | <a href="https://attack.mitre.org/tactics/TA0003/" target="_blank">TA0003 - Persistence</a><br><a href="https://attack.mitre.org/techniques/T1550/" target="_blank">T1550 - Use Alternate Authentication Material</a> |
| Stages | Stage_Name<br>Created<br>Last_Altered<br>Deleted | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1074/" target="_blank">T1074 - Data Staged</a> |
| Users | All Applicable Columns | Account_Usage | 2 hours | <a href="https://attack.mitre.org/tactics/TA0003/" target="_blank">TA0003 - Persistence</a><br><a href="https://attack.mitre.org/tactics/TA0003/" target="_blank">TA0003 - Valid Accounts</a> |
| Databases | Database_Name<br>Created<br>Last_Altered<br>Deleted | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1074/" target="_blank">T1074 - Data Staged</a> |
| Tables | Table_Owner<br>Created<br>Last_Altered<br>Deleted | Account_Usage | 2 hours | <a href="https://attack.mitre.org/techniques/T1074/" target="_blank">T1074 - Data Staged</a> |










*The information contained in this document is provided for informational purposes only and shall not create any representations or other obligations. Snowflake’s commitments are exclusively contained within the agreement signed between your organization and Snowflake.*

*Please note that more information on Snowflake’s Service, as well as the security and privacy controls for which our customers are responsible, can be found in our Security Addendum, and within our Product Documentation at the following links: Snowflake Editions, Snowflake Hosting Regions, and Managing Security in Snowflake, which includes information on authentication controls, pseudonymization, and customer-managed encryption keys. Our Documentation also includes information on data back-up and disaster recovery options for our customers’ data if our customers choose to configure them.*