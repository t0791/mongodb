INSERT INTO UM_HYBRID_USER_ROLE (UM_USER_NAME,UM_ROLE_ID,UM_TENANT_ID,UM_DOMAIN_ID) VALUES ('subscriber',(SELECT UM_ID FROM UM_HYBRID_ROLE WHERE UM_ROLE_NAME='subscriber'),-1234,1);

INSERT INTO UM_USER (UM_USER_NAME,UM_USER_PASSWORD,UM_SALT_VALUE,UM_REQUIRE_CHANGE,UM_CHANGED_TIME,UM_TENANT_ID) VALUES('topus','/FhmkFrBInziVUflJuIt4v6F9jaJZDlyuGVsjnjYU1E=','GIAuCBTSIA4ITubEqJ37+w==',0,'2014-11-25 17:33:27.609',-1234);

INSERT INTO UM_USER (UM_USER_NAME,UM_USER_PASSWORD,UM_SALT_VALUE,UM_REQUIRE_CHANGE,UM_CHANGED_TIME,UM_TENANT_ID) VALUES('subscriber','3sQ0uBAowYje1+xhiDrcY9ue7S1uZcD+bsCrZG4EvUs=','uRm7LIVMlBr5HYKiLosU6g==',0,'2014-11-25 17:33:28.609',-1234);

INSERT INTO UM_USER (UM_USER_NAME,UM_USER_PASSWORD,UM_SALT_VALUE,UM_REQUIRE_CHANGE,UM_CHANGED_TIME,UM_TENANT_ID) VALUES('provider','urunhJG9lfc3u5yliZY+5bg7cEnM9gHzW5Zvw5CRx8E=','JKwiZ0VwsDWOpbQJpiFAuw==',0,'2014-11-25 17:33:29.609',-1234);

INSERT INTO UM_USER_ROLE (UM_ROLE_ID,UM_USER_ID,UM_TENANT_ID) VALUES((SELECT UM_ID FROM UM_ROLE WHERE UM_ROLE_NAME='admin'),(SELECT UM_ID FROM UM_USER WHERE UM_USER_NAME='topus'),-1234);

INSERT INTO UM_HYBRID_ROLE (UM_ROLE_NAME, UM_TENANT_ID) VALUES ('provider', -1234);

INSERT INTO UM_HYBRID_USER_ROLE (UM_USER_NAME,UM_ROLE_ID,UM_TENANT_ID,UM_DOMAIN_ID) VALUES ('provider',(SELECT UM_ID FROM UM_HYBRID_ROLE WHERE UM_ROLE_NAME='provider'),-1234,1);

INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/permission/admin/manage/api/create','ui.execute',-1234,0);
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/_system/governance/trunk','http://www.wso2.org/projects/registry/actions/get',-1234,0);
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/_system/governance/trunk','http://www.wso2.org/projects/registry/actions/add',-1234,0);
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/_system/governance/trunk','http://www.wso2.org/projects/registry/actions/delete',-1234,0);
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/_system/governance/apimgt/applicationdata','http://www.wso2.org/projects/registry/actions/get',-1234,0); 
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/_system/governance/apimgt/applicationdata','http://www.wso2.org/projects/registry/actions/add',-1234,0); 
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/_system/governance/apimgt/applicationdata','http://www.wso2.org/projects/registry/actions/delete',-1234,0);
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/permission/admin/manage/api/publish','ui.execute',-1234,0);
INSERT INTO UM_PERMISSION (UM_RESOURCE_ID,UM_ACTION,UM_TENANT_ID,UM_MODULE_ID) VALUES('/permission/admin/manage/mediation','ui.execute',-1234,0);

INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES (17,'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES (18,'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES (11,'provider',1,-1234,3);

INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES ((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/permission/admin/manage/api/create' AND UM_ACTION='ui.execute'),'provider',1,-1234,3);

INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/permission/admin/manage/api/publish' AND UM_ACTION='ui.execute'),'provider',1,-1234,3);

INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/_system/governance/trunk' AND UM_ACTION='http://www.wso2.org/projects/registry/actions/get'),'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/_system/governance/trunk' AND UM_ACTION='http://www.wso2.org/projects/registry/actions/add'),'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/_system/governance/trunk' AND UM_ACTION='http://www.wso2.org/projects/registry/actions/delete'),'provider',1,-1234,3);

INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/_system/governance/apimgt/applicationdata' AND UM_ACTION='http://www.wso2.org/projects/registry/actions/get'),'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/_system/governance/apimgt/applicationdata' AND UM_ACTION='http://www.wso2.org/projects/registry/actions/add'),'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/_system/governance/apimgt/applicationdata' AND UM_ACTION='http://www.wso2.org/projects/registry/actions/delete'),'provider',1,-1234,3);
INSERT INTO UM_ROLE_PERMISSION (UM_PERMISSION_ID,UM_ROLE_NAME,UM_IS_ALLOWED,UM_TENANT_ID,UM_DOMAIN_ID) VALUES((SELECT UM_ID FROM UM_PERMISSION WHERE UM_RESOURCE_ID='/permission/admin/manage/mediation' AND UM_ACTION='ui.execute'),'provider',1,-1234,3);

commit;