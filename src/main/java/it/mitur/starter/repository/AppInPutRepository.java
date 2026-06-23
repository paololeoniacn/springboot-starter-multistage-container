package it.mitur.starter.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import it.mitur.starter.entity.AppInPut;

// ═══════════════════════════════════════════════════════════════════════════
// TODO: RENAME — dopo aver rinominato AppInPut, aggiorna questo repository:
//   - Classe: 'AppInPutRepository' → '{Prefisso}InPutRepository'
//   - Tipo: 'AppInPut' → il nuovo tipo dell'entità rinominata
// ═══════════════════════════════════════════════════════════════════════════
@Repository
public interface AppInPutRepository extends JpaRepository<AppInPut, Integer> {

    // Spring Data JPA genera automaticamente le query CRUD base.
    // Aggiungere qui i metodi derivati necessari al tuo dominio.
    // Esempi:
    //   Optional<AppInPut> findByIdentifier(String identifier);
    //   List<AppInPut> findByStatus(String status);
    //   List<AppInPut> findByIdFlow(String idFlow);
}
