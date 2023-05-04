/**
 * @description class for handling configuration (key/value pairs)
 * This software package is licensed under the Booz Allen Public License. 
 * Copyright © 2023 Booz Allen Hamilton Inc.  All Rights Reserved.
 * 
 * @author Jonathan Devlin
 */
public without sharing class ZD_Configuration {
    
    @TestVisible private Cache cache;

    private String defaultApp;

    /**
     * @description metadata type api name
     */
    public static final String APP_CONFIG_MDT_NAME = 'ApplicationConfiguration__mdt';

    /**
     * @description exception class
     */
    public class ZD_ConfigurationException extends Exception{}

    /**
     * @description constructor with no default app set
     */
    public ZD_Configuration() {
        cache = new Cache();
    }

    /**
     * @description constructor with a default app
     * @param defaultApp - defaultApp to load config for
     */
    public ZD_Configuration(String defaultApp) {
        this();
        this.defaultApp = defaultApp;
        loadConfig(defaultApp);
    }

    /**
     * @description loads the metadata records into setting instances
     * @param appName - app name to lod the config for
     */
    public void loadConfig(String appName){
        List<ZD_Configuration.Setting> settings = getApplicationConfiguration(ZD_DatabaseService.queryWithBinds('SELECT Key__c, Value__c, Application__r.DeveloperName FROM ZD_ApplicationConfiguration__mdt WHERE Application__r.DeveloperName =: appName', 
                                                                                new Map<String,Object>{'appName' => appName}, 
                                                                                System.accessLevel.SYSTEM_MODE));
        for(ZD_Configuration.Setting setting : settings){
            cache.addToCache(setting);
        }
    }

    /**
     * @description gets a value from a key when a default app is set
     * @param key - key for value at the default app
     * @return value held at the key for the default app
     */
    public String get(String key){
        if(defaultApp == null){
            throw new ZD_ConfigurationException('No default app set, please provide an application name');
        }
        return cache.getFromCache(defaultApp, key);
    }

    /**
     * @description gets keys for the default app
     * @return Set<String> representing all keys for the default app
     */
    public Set<String> keySet(){
        if(defaultApp == null){
            throw new ZD_ConfigurationException('No default app set, please provide an application name');
        }
        return cache.getKeysFromCache(defaultApp);
    }

    /**
     * @description returns a value at a key for a given app
     * @param app - application to check config for
     * @param key - key to retrieve value for
     * @return String value at a key for an app
     */
    public String get(String app, String key){
        return cache.getFromCache(app, key);
    }

    /**
     * @description gets keys for a given app
     * @param app - app to get the keys for
     * @return Set<String> representing all keys for passed in app
     */
    public Set<String> keySet(String app){
        return cache.getKeysFromCache(app);
    }

    /**
     * @description converts mdt records to setting instances
     * @param mdtRecords - list of mdtRecords to convert to Settings
     * @return List<Setting> representing the mdt records
     */
    private List<Setting> getApplicationConfiguration(List<SObject> mdtRecords){
        List<Setting> settings = new List<Setting>();
        for(SObject settingMdt : mdtRecords){
            settings.add(new Setting(settingMDT));
        }
        return settings;
    }

    /**
     * @description class to hold settings so that queries dont have to be run
     * multiple times
     */
    public class Cache{
        private Map<String,Map<String,String>> valueCache = new Map<String,Map<String,String>>();

        /**
         * @description adds a setting to the cache for fast retrieval later
         * @param setting - setting to cache
         */
        public void addToCache(ZD_Configuration.Setting setting){
            if(valueCache.get(setting.application) == null){
                valueCache.put(setting.application, new Map<String,String>());
            }
            valueCache.get(setting.application).put(setting.key, setting.value);
        }

        /**
         * @description gets value from cache for a given app/key combo
         * @param app - app to check
         * @param key - key for this value
         * @return String value for that key
         */
        public String getFromCache(String app, String key){
            if(valueCache.get(app) == null){
                throw new ZD_ConfigurationException('Application: ' + app + ' config has not been loaded');
            }
            return valueCache.get(app).get(key);
        }

        /**
         * @description gets keys from cache for a given app
         * @param app - app to check
         * @return set of keys for a given app
         */
        public Set<String> getKeysFromCache(String app){
            if(valueCache.get(app) == null){
                throw new ZD_ConfigurationException('Application: ' + app + ' config has not been loaded');
            }
            return valueCache.get(app)?.keySet();
        }
    }

    /**
     * @description represents a setting key/value pair for a given app
     */
    public class Setting{
        /**
         * @description key for config
         */
        public String key {public get; private set;}
        /**
         * @description value stored at a given key
         */
        public String value {public get; private set;}
        /**
         * @description application this setting belongs to
         */
        public String application {public get; private set;}

        /**
         * @description creates a setting from a custom metadata type record
         * @param mdtRecord - custom metadata record to get the setting properties from
         */
        public Setting(SObject mdtRecord){
            this((String) mdtRecord.getSObject('Application__r').get('DeveloperName'),(String) mdtRecord.get('Key__c'),(String) mdtRecord.get('Value__c'));
        }

        /**
         * @description allows creating settings for tests with no mdt records
         * @param application - app for this setting
         * @param key - key this setting value is stored at
         * @param value - value of the setting
         */
        @TestVisible 
        private Setting(String application, String key, String value){
            this.key = key;
            this.value = value;
            this.application = application;
        }
    }
}