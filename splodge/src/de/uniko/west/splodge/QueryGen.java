package de.uniko.west.splodge;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.zip.GZIPInputStream;

/**
 * SPLODGE Query Generator
 * 
 * @author Olaf Goerlitz (goerlitz@uni-koblenz.de)
 */
public class QueryGen {
	
	private static final String PATH_STATS = "path-stats.gz";
	private static final String PREDICATES = "predicate-list.gz";
	private static final String CONTEXTS   = "context-list.gz";
	private static final Random RAND = new Random(42);
	private static final int QUERIES = 10;
	
	private PathStatistics pStats = new PathStatistics(RAND);
	private Map<Integer, String> pIndex = new HashMap<Integer, String>();
	private Map<Integer, String> cIndex = new HashMap<Integer, String>();
	
	
	public QueryGen() {}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		QueryGen gen = new QueryGen();

		// loading statistics
		gen.loadStatistics();
		gen.loadDisctionaries();

		// loading configuration
		
		// generating queries
		gen.generateQueries(QUERIES);
	}
	
	public void loadStatistics() {
		try {
			pStats.loadPathStatistics(openReader(new File(PATH_STATS)));
		} catch (FileNotFoundException e) {
			System.err.println("Error: file not found. " + e.getMessage());
			System.exit(1);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void loadDisctionaries() {
		try {
			loadDictionary(openReader(new File(PREDICATES)), pIndex);
			loadDictionary(openReader(new File(CONTEXTS)), cIndex);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void loadDictionary(BufferedReader reader, Map<Integer, String> map) throws IOException {
		int pos = 0;
		String line = "";
		
		while ((line = reader.readLine()) != null) {
			map.put(pos++, line);
		}
	}
	
	public void generatePathJoin(int numPatterns, int numSources) {
		
		int retries = 0;
		List<Pair> pathJoin = new ArrayList<Pair>();
		
		while (pathJoin.size() < numPatterns) {

			if (pathJoin.size() == 0) {
				int[] choice = pStats.pickPathJoin();
				pathJoin.add(new Pair(choice[0], choice[1]));
				pathJoin.add(new Pair(choice[2], choice[3]));
				//				System.out.println("new path: " + Arrays.toString(choice));
				continue;
			}

			Pair last = pathJoin.get(pathJoin.size()-1);
			if (pStats.exists(last.predicate, last.source)) {
				int[] choice = pStats.pickPathJoin(last.predicate, last.source);
				pathJoin.add(new Pair(choice[2], choice[3]));
			} else {
				// no path available
				pathJoin = new ArrayList<Pair>();
				retries++;
			}

		}

		System.out.println("new path: " + pathJoin + ", retries: " + retries);
		
		for (Pair p : pathJoin) {
			System.out.println("tp: " + pIndex.get(p.predicate) + " @ " + cIndex.get(p.source));
		}

		pathJoin = new ArrayList<Pair>();
	}
	
	public void generateQueries(int runs) {
		
		for (int i =0; i< runs; i++) {
			generatePathJoin(4, 4);
		}
	}
	
	private static final BufferedReader openReader(File file) throws FileNotFoundException, IOException {
		InputStream in = new FileInputStream(file);
		if (file.getName().endsWith(".gz"))
			in = new GZIPInputStream(in);
		return new BufferedReader(new InputStreamReader(in));
	}
	
	public class Pair {
		int predicate;
		int source;
		
		public Pair(int predicate, int source) {
			this.predicate = predicate;
			this.source = source;
		}
		
		public String toString() {
			return "[" + predicate + ", " + source + "]";
		}
	}
	
}
