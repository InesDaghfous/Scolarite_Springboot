package org.isetn;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.rest.core.config.RepositoryRestConfiguration;
import org.springframework.data.rest.webmvc.config.RepositoryRestConfigurer;

@Configuration
public class GlobalRepositoryRestConfigurer implements RepositoryRestConfigurer {
    @Override
    public void configureRepositoryRestConfiguration(RepositoryRestConfiguration config) {
        config.setReturnBodyOnCreate(true);
        config.setReturnBodyOnUpdate(true);

        // Exposer les IDs pour toutes les entités
        config.exposeIdsFor(
            Etudiant.class,
            Formation.class,
            Classe.class,
            Departement.class,
            Absence.class,
            Note.class
        );

        config.getCorsRegistry()
            .addMapping("/**")
            .allowedOrigins("*")
            .allowedHeaders("*")
            .allowedMethods("OPTIONS", "HEAD", "GET", "PUT", "POST", "DELETE", "PATCH");
    }
}
