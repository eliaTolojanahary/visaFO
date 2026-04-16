package main;

import annotation.MethodeAnnotation;
import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.PostMapping;
import annotation.RequestParam;
import annotation.Api;
import java.util.*;

@ClasseAnnotation("ApiExample controller")
public class ApiExample {

    @Api
    @MethodeAnnotation("/api/account")
    @GetMapping
    public Account getAccount(@RequestParam("id") int id) {
        return new Account(id, "Name" + id);
    }

    @Api
    @MethodeAnnotation("/api/accounts")
    @GetMapping
    public List<Account> listAccounts() {
        List<Account> l = new ArrayList<>();
        l.add(new Account(1, "Alice"));
        l.add(new Account(2, "Bob"));
        return l;
    }

    @Api
    @MethodeAnnotation("/api/createAccount")
    @PostMapping
    public Account createAccount(@RequestParam("name") String name) {
        return new Account(new java.util.Random().nextInt(1000), name);
    }

    @Api
    @MethodeAnnotation("/api/upload")
    @PostMapping
    public java.util.Map<String, Object> uploadFile(@RequestParam("file") FileUpload file, @RequestParam("desc") String desc) {
        java.util.Map<String, Object> res = new java.util.HashMap<>();
        if (file != null) {
            res.put("filename", file.getFilename());
            res.put("size", file.getSize());
            res.put("contentType", file.getContentType());
            res.put("desc", desc != null ? desc : "");
            res.put("savedPath", file.getSavedPath());
        } else {
            res.put("status", "no_file");
        }
        return res;
    }

    @Api
    @MethodeAnnotation("/api/uploadRaw")
    @PostMapping
    public java.util.Map<String, Object> uploadRaw(@RequestParam("file") byte[] fileContent, @RequestParam("filename") String filename, @RequestParam("desc") String desc) {
        java.util.Map<String, Object> res = new java.util.HashMap<>();
        if (fileContent != null) {
            String name = (filename != null && !filename.isEmpty()) ? filename : ("upload_" + System.currentTimeMillis());
            main.FileUpload fu = new main.FileUpload(fileContent, name, "application/octet-stream", fileContent.length);
            // Try to save to fallback uploads folder (user.dir/uploads)
            try {
                java.io.File dir = new java.io.File(System.getProperty("user.dir"), "uploads");
                if (!dir.exists()) dir.mkdirs();
                java.io.File target = new java.io.File(dir, name);
                java.nio.file.Files.write(target.toPath(), fileContent);
                fu.setSavedPath(target.getAbsolutePath());
            } catch (Throwable t) {
                fu.setSavedPath(null);
            }
            res.put("filename", fu.getFilename());
            res.put("size", fu.getSize());
            res.put("contentType", fu.getContentType());
            res.put("desc", desc != null ? desc : "");
            res.put("savedPath", fu.getSavedPath());
        } else {
            res.put("status", "no_file");
        }
        return res;
    }

    @Api
    @MethodeAnnotation("/api/modelview")
    @GetMapping
    public modelview.ModelView mvExample() {
        Map<String, Object> data = new HashMap<>();
        data.put("id", 123);
        data.put("name", "mvName");
        modelview.ModelView mv = new modelview.ModelView("/etudiant-test-ok.jsp", data);
        return mv;
    }
}
