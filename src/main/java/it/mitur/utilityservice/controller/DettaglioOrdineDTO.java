package it.mitur.utilityservice.controller;

public class DettaglioOrdineDTO {
    private String descrizione;
    private int quantita;

    // Getters e Setters
    public String getDescrizione() { return descrizione; }
    public void setDescrizione(String descrizione) { this.descrizione = descrizione; }

    public int getQuantita() { return quantita; }
    public void setQuantita(int quantita) { this.quantita = quantita; }
}
