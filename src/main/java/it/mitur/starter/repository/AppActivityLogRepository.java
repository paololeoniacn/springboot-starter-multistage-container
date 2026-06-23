package it.mitur.starter.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import it.mitur.starter.entity.AppActivityLog;

// ═══════════════════════════════════════════════════════════════════════════
// TODO: RENAME — dopo aver rinominato AppActivityLog, aggiorna questo repository:
//   - Classe: 'AppActivityLogRepository' → '{Prefisso}ActivityLogRepository'
//   - Tipo: 'AppActivityLog' → il nuovo tipo dell'entità rinominata
// ═══════════════════════════════════════════════════════════════════════════
@Repository
public interface AppActivityLogRepository extends JpaRepository<AppActivityLog, Integer> {

    // Spring Data JPA genera automaticamente le query CRUD base.
    // Aggiungere qui i metodi derivati necessari al tuo dominio.
    // Esempi:
    //   List<AppActivityLog> findByIdRequest(Integer idRequest);
    //   List<AppActivityLog> findByIdRequestOrderByCreatedAtAsc(Integer idRequest);
}
