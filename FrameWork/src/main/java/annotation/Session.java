package annotation;

import java.lang.annotation.*;
import java.util.Map;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Session {
}
