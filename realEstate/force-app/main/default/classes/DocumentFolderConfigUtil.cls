public class DocumentFolderConfigUtil {
    
    public class FolderConfig {
        public String name;
        public Integer sequence;
        public Boolean required;
    }
    
    public static Map<String, List<FolderConfig>> parseConfig(String jsonString) {
        
        Map<String, List<FolderConfig>> result =
            new Map<String, List<FolderConfig>>();
        
        if (String.isBlank(jsonString)) {
            return result;
        }
        
        // ✅ CORRECT METHOD CALL
        Map<String, Object> root =
            (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        for (String objectName : root.keySet()) {
            
            List<Object> rawList = (List<Object>) root.get(objectName);
            List<FolderConfig> folders = new List<FolderConfig>();
            
            Integer seq = 1;
            
            for (Object item : rawList) {
                
                FolderConfig fc = new FolderConfig();
                
                // 🔹 OBJECT FORMAT (Lead)
                if (item instanceof Map<String, Object>) {
                    
                    Map<String, Object> m =
                        (Map<String, Object>) item;
                    
                    fc.name = (String) m.get('name');
                    fc.sequence = (Integer) m.get('sequence');
                    fc.required = (Boolean) m.get('required');
                }
                // 🔹 STRING FORMAT (Account / Opportunity)
                else {
                    fc.name = String.valueOf(item);
                    fc.sequence = seq;
                    fc.required = false;
                }
                
                folders.add(fc);
                seq++;
            }
            
            result.put(objectName, folders);
        }
        system.debug('Here is the result-->'+result);
        return result;
    }
}