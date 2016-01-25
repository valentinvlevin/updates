package kz.testcenter.updates.common;

import javax.json.*;
import javax.json.stream.JsonGenerator;
import java.io.StringWriter;
import java.util.List;

/**
 * Created by user on 19.03.2015.
 */
public class MyJsonBuilder {
    private static void buildJsonOfRow(
            JsonGenerator generator,
            int columnCount,
            String[] columns,
            Object[] row)
    {
        generator.writeStartObject();
        for (int valueIndex=0; valueIndex<columnCount; valueIndex++) {
            if (row[valueIndex] == null)
                generator.write(columns[valueIndex], "");
            else if (row[valueIndex].getClass() ==  Long.class)
                generator.write(columns[valueIndex], (Long)(row[valueIndex]));
            else if (row[valueIndex].getClass() == Integer.class)
                generator.write(columns[valueIndex], (Integer)(row[valueIndex]));
            else if (row[valueIndex].getClass() == Short.class)
                generator.write(columns[valueIndex], (Short)row[valueIndex]);
            else if (row[valueIndex].getClass() == String.class)
                generator.write(columns[valueIndex], (String)row[valueIndex]);
            else if (row[valueIndex].getClass() == Float.class)
                generator.write(columns[valueIndex], (Float)row[valueIndex]);
            else if (row[valueIndex].getClass() == Double.class)
                generator.write(columns[valueIndex], (Double)row[valueIndex]);
            else if (row[valueIndex].getClass() == Boolean.class)
                generator.write(columns[valueIndex], (Boolean)row[valueIndex]);
            else if (row[valueIndex].getClass() == Byte.class)
                generator.write(columns[valueIndex], (Byte)row[valueIndex]);
            else generator.write(columns[valueIndex], row[valueIndex].toString());
        }
        generator.writeEnd();
    }

    public static String buildJsonArray(String[] columns, List<Object[]> data) {
        StringWriter writer = new StringWriter();
        JsonGenerator generator = Json.createGenerator(writer);

        generator.writeStartArray();
        for (Object[] row : data)
            buildJsonOfRow(generator, columns.length, columns, row);
        generator.writeEnd();
        generator.close();

        return writer.toString();
    }

    public static String buildJsonObject(String[] columns, Object data) {
        StringWriter writer = new StringWriter();
        JsonGenerator generator = Json.createGenerator(writer);
        buildJsonOfRow(generator, columns.length, columns, (Object[]) data);
        generator.close();
        return writer.toString();
    }
}
