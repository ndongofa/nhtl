package com.nhtl.models;

public enum DepartureStatus {
    DRAFT,      // brouillon — visible uniquement admin
    PUBLISHED,  // publié — visible sur la landing/home
    ARCHIVED    // archivé — masqué partout
}