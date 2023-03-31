public without sharing class ZD_Configuration {
    
    @TestVisible private Cache cache;

    private String defaultApp;

    public static final String APP_CONFIG_MDT_NAME = 'ApplicationConfiguration__mdt';

    public class ZD_ConfigurationException extends Exception{}

    public ZD_Configuration() {
        cache = new Cache();
    }

    public ZD_Configuration(String defaultApp) {
        this();
        this.defaultApp = defaultApp;
        loadConfig(defaultApp);
    }

    public void loadConfig(String appName){
        List<ZD_Configuration.Setting> settings = getApplicationConfiguration(ZD_DatabaseService.queryWithBinds('SELECT Key__c, Value__c, Application__r.DeveloperName FROM ZD_ApplicationConfiguration__mdt WHERE Application__r.DeveloperName =: appName', 
                                                                                new Map<String,Object>{'appName' => appName}, 
                                                                                System.accessLevel.SYSTEM_MODE));
        for(ZD_Configuration.Setting setting : settings){
            cache.addToCache(setting);
        }
    }

    public String get(String key){
        if(defaultApp == null){
            throw new ZD_ConfigurationException('No default app set, please provide an application name');
        }
        return cache.getFromCache(defaultApp, key);
    }

    public Set<String> keySet(){
        if(defaultApp == null){
            throw new ZD_ConfigurationException('No default app set, please provide an application name');
        }
        return cache.getKeysFromCache(defaultApp);
    }

    public String get(String app, String key){
        return cache.getFromCache(app, key);
    }

    public Set<String> keySet(String app){
        return cache.getKeysFromCache(app);
    }

    private List<Setting> getApplicationConfiguration(List<SObject> mdtRecords){
        List<Setting> settings = new List<Setting>();
        for(SObject settingMdt : mdtRecords){
            settings.add(new Setting(settingMDT));
        }
        return settings;
    }

    public class Cache{
        private Map<String,Map<String,String>> valueCache = new Map<String,Map<String,String>>();

        public void addToCache(ZD_Configuration.Setting setting){
            if(valueCache.get(setting.application) == null){
                valueCache.put(setting.application, new Map<String,String>());
            }
            valueCache.get(setting.application).put(setting.key, setting.value);
        }

        public String getFromCache(String app, String key){
            if(valueCache.get(app) == null){
                throw new ZD_ConfigurationException('Application: ' + app + ' config has not been loaded');
            }
            return valueCache.get(app).get(key);
        }

        public Set<String> getKeysFromCache(String app){
            if(valueCache.get(app) == null){
                throw new ZD_ConfigurationException('Application: ' + app + ' config has not been loaded');
            }
            return valueCache.get(app)?.keySet();
        }
    }

    public class Setting{
        public String key {public get; private set;}
        public String value {public get; private set;}
        public String application {public get; private set;}

        public Setting(SObject mdtZD_Record){
            this((String) mdtZD_Record.getSObject('Application__r').get('DeveloperName'),(String) mdtZD_Record.get('Key__c'),(String) mdtZD_Record.get('Value__c'));
        }

        @TestVisible 
        private Setting(String application, String key, String value){
            this.key = key;
            this.value = value;
            this.application = application;
        }
    }
}