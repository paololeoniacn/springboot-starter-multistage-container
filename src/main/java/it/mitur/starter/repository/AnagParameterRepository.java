package it.mitur.starter.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import it.mitur.starter.entity.AnagParameter;

/**
 * Repository per la tabella anag_parameter.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Esempi di utilizzo:
 *   // Tutti i parametri di un flusso
 *   List<AnagParameter> list = anagRepo.findByCdFlow("MY_FLOW");
 *
 *   // Parametro specifico
 *   Optional<AnagParameter> p = anagRepo.findByCdFlowAndCdTypeAndCdKey("MY_FLOW","CONFIG","MAX_RETRY");
 */
@Repository
public interface AnagParameterRepository extends JpaRepository<AnagParameter, Integer> {

    List<AnagParameter> findByCdFlow(String cdFlow);

    List<AnagParameter> findByCdFlowAndCdType(String cdFlow, String cdType);

    Optional<AnagParameter> findByCdFlowAndCdTypeAndCdKey(String cdFlow, String cdType, String cdKey);
}
