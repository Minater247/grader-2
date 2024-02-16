import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.stream.Stream;

class ExecHelpers {

    /**
     * Takes an input stream, reads the full stream, and returns the result as a
     * string.
     * 
     * In Java 9 and later, new String(out.readAllBytes()) would be a better
     * option, but using Java 8 for compatibility with ieng6.
     */
    static String streamToString(InputStream out) throws IOException {
        String result = "";
        while (true) {
            int c = out.read();
            if (c == -1) {
                break;
            }
            result += (char) c;
        }
        return result;
    }

    /**
     * Takes a command, represented as an array of strings as it would by typed at
     * the command line, runs it, and returns its combined stdout and stderr as a
     * string.
     */
    static String exec(String[] cmd) throws IOException {
        Process p = new ProcessBuilder()
                .command(Arrays.asList(cmd))
                .redirectErrorStream(true)
                .start();
        InputStream outputOfBash = p.getInputStream();
        return String.format("%s\n", streamToString(outputOfBash));
    }

}

class Handler implements URLHandler {
    public String handleRequest(URI url) throws IOException {
        if (url.getPath().equals("/grade")) {
            String[] parameters = url.getQuery().split("=");
            if (parameters[0].equals("repo")) {
                String[] cmd = { "bash", "grade.sh", "-s", parameters[1] };
                String result = ExecHelpers.exec(cmd);

                // The last line is just the final grade as a decimal number
                String[] lines = result.split("\n");
                
                // for some forsaken reason, HTML treats \r as a newline character
                // so we need to handle it manually before returning the result
                for (int i = 0; i < lines.length; i++) {
                    if (lines[i].contains("\r")) {
                        String pre_r = lines[i].substring(0, lines[i].indexOf("\r"));
                        String post_r = lines[i].substring(lines[i].indexOf("\r") + 1);
                        pre_r = pre_r.substring(post_r.length(), pre_r.length());
                        lines[i] = post_r + pre_r;
                    }
                }

                double grade = Double.parseDouble(lines[lines.length - 1]);
                lines[lines.length - 1] = String.format("%.0f%%", grade * 100);

                result = String.join("\n", lines);
                return result;
            } else {
                return "Couldn't find query parameter repo";
            }
        } else {
            return "Don't know how to handle that path!";
        }
    }
}

class GradeServer {
    public static void main(String[] args) throws IOException {
        if (args.length == 0) {
            System.out.println("Missing port number! Try any number between 1024 to 49151");
            return;
        }

        int port = Integer.parseInt(args[0]);

        Server.start(port, new Handler());
    }
}

class ExecExamples {
    public static void main(String[] args) throws IOException {
        String[] cmd1 = { "ls", "lib" };
        System.out.println(ExecHelpers.exec(cmd1));

        String[] cmd2 = { "pwd" };
        System.out.println(ExecHelpers.exec(cmd2));

        String[] cmd3 = { "touch", "a-new-file.txt" };
        System.out.println(ExecHelpers.exec(cmd3));
    }
}
