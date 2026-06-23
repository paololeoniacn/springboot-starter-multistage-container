package it.mitur.starter.dto.common;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO per le operazioni di upload su S3.
 *
 * Pronto all'uso — nessun TODO: RENAME necessario.
 *
 * Usato da S3Service e AuditHelper per incapsulare path e contenuto
 * da caricare su S3.
 *
 * Esempio:
 *   S3Request req = new S3Request("internal/starter/myService/request/ABC/20240101T120000000", jsonString);
 *   s3Service.process(req);
 *
 * Il campo pathS3 viene usato come chiave S3 (senza estensione):
 *   S3Service aggiunge automaticamente .json e .trg, e scrive il backup.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class S3Request {

    /** Path S3 (senza estensione) — es. "internal/starter/myService/request/ABC/20240101T120000000" */
    private String pathS3;

    /** Contenuto JSON da caricare. */
    private String jsonString;
}
