package com.nhtl.models;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.ArrayList;
import java.util.List;

/**
 * JPA converter: persists List&lt;String&gt; as a JSON array in a TEXT column.
 */
@Converter
public class StringListConverter implements AttributeConverter<List<String>, String> {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(List<String> list) {
        if (list == null || list.isEmpty()) return null;
        try {
            return MAPPER.writeValueAsString(list);
        } catch (JsonProcessingException e) {
            return null;
        }
    }

    @Override
    public List<String> convertToEntityAttribute(String json) {
        if (json == null || json.isBlank()) return new ArrayList<>();
        try {
            return MAPPER.readValue(json, new TypeReference<List<String>>() {});
        } catch (JsonProcessingException e) {
            return new ArrayList<>();
        }
    }
}
